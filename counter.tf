# ---------------------------------------------------------------------------
# Contatore globale "RIP Pierone" - DynamoDB + Lambda + API Gateway HTTP API
# Da integrare nello stack staticsiteterraformstack
# ---------------------------------------------------------------------------

variable "allowed_origin" {
  description = "Origin autorizzato per le chiamate CORS al contatore"
  type        = string
  default     = "https://www.marcocavalieri.it"
}

# --- DynamoDB: tabella con un solo record contatore ---
resource "aws_dynamodb_table" "respect_counter" {
  name         = "respect-counter"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # Cancella automaticamente le righe "ip#<ip>" usate per il rate-limit,
  # senza costi extra e senza bisogno di pulizia manuale
  ttl {
    attribute_name = "ttl"
    enabled        = true
  }
}

# --- IAM Role per la Lambda ---
resource "aws_iam_role" "counter_lambda_role" {
  name = "respect-counter-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "counter_lambda_policy" {
  name = "respect-counter-lambda-policy"
  role = aws_iam_role.counter_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["dynamodb:UpdateItem"]
        Resource = aws_dynamodb_table.respect_counter.arn
      },
      {
        Effect   = "Allow"
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# --- Lambda ---
data "archive_file" "counter_lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda-counter"
  output_path = "${path.module}/lambda-counter.zip"
}

resource "aws_lambda_function" "respect_counter" {
  function_name    = "respect-counter"
  role             = aws_iam_role.counter_lambda_role.arn
  handler          = "index.handler"
  runtime          = "nodejs20.x"
  filename         = data.archive_file.counter_lambda_zip.output_path
  source_code_hash = data.archive_file.counter_lambda_zip.output_base64sha256

  # Limita le esecuzioni concorrenti: anche in caso di flood, non può
  # scalare oltre questo numero, quindi il danno economico resta limitato
  reserved_concurrent_executions = 5

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.respect_counter.name
    }
  }
}

# --- API Gateway HTTP API (più economico del REST API) ---
resource "aws_apigatewayv2_api" "counter_api" {
  name          = "respect-counter-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = [var.allowed_origin]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["Content-Type"]
  }
}

resource "aws_apigatewayv2_integration" "counter_integration" {
  api_id                 = aws_apigatewayv2_api.counter_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.respect_counter.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "counter_route_get" {
  api_id    = aws_apigatewayv2_api.counter_api.id
  route_key = "GET /respect"
  target    = "integrations/${aws_apigatewayv2_integration.counter_integration.id}"
}

resource "aws_apigatewayv2_route" "counter_route_post" {
  api_id    = aws_apigatewayv2_api.counter_api.id
  route_key = "POST /respect"
  target    = "integrations/${aws_apigatewayv2_integration.counter_integration.id}"
}

# OPTIONS gestito automaticamente dalla cors_configuration dell'API,
# ma se serve esplicito lo aggiungiamo qui:
resource "aws_apigatewayv2_route" "counter_route_options" {
  api_id    = aws_apigatewayv2_api.counter_api.id
  route_key = "OPTIONS /respect"
  target    = "integrations/${aws_apigatewayv2_integration.counter_integration.id}"
}

resource "aws_apigatewayv2_stage" "counter_stage" {
  api_id      = aws_apigatewayv2_api.counter_api.id
  name        = "$default"
  auto_deploy = true

  # Throttling generale di default per tutte le route non specificate
  default_route_settings {
    throttling_rate_limit  = 10 # richieste/secondo sostenute
    throttling_burst_limit = 20 # picco massimo istantaneo
  }

  # Throttling più stretto sulla POST (l'unica che scrive/incrementa)
  route_settings {
    route_key               = aws_apigatewayv2_route.counter_route_post.route_key
    throttling_rate_limit   = 2  # max 2 incrementi/secondo sostenuti
    throttling_burst_limit  = 5  # picco massimo 5 di colpo
  }

  # La GET (sola lettura) può restare più permissiva
  route_settings {
    route_key               = aws_apigatewayv2_route.counter_route_get.route_key
    throttling_rate_limit   = 10
    throttling_burst_limit  = 20
  }
}

resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.respect_counter.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.counter_api.execution_arn}/*/*"
}

output "counter_api_endpoint" {
  value = aws_apigatewayv2_api.counter_api.api_endpoint
}
