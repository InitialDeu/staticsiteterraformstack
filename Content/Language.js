document.addEventListener("DOMContentLoaded", () => {

  let currentLang = "it";
  document.documentElement.lang = currentLang;

  function translatePage(lang) {
    document.querySelectorAll("[data-i18n]").forEach(el => {
      const keys = el.dataset.i18n.split(".");
      let value = translations[lang];

      keys.forEach(k => {
        value = value?.[k];
      });

      if (value) el.textContent = value;
    });

    currentLang = lang;
  }

  const toggleBtn = document.getElementById("langToggle");

  toggleBtn.addEventListener("click", () => {
    const next = currentLang === "it" ? "en" : "it";
    translatePage(next);
    toggleBtn.textContent = next === "it" ? "🇬🇧 EN" : "🇮🇹 IT";
  });

  translatePage("it");

});



const translations = {
  it: {
    hero: {
      name: "Marco Cavalieri",
      role: "Consulente Informatico"
    },

    nav: {
      profile: "Profilo",
      experience: "Esperienza",
      education: "Formazione",
      certifications: "Certificazioni",
      projects: "Progetti"
    },

    profile: {
      title: "Profilo",
      text:
        "Ciao! Sono Marco, classe 2000 e un appassionato di tecnologia a 360 gradi. " +
        "Sin da quando ero piccolo mi sono sempre approcciato al computer " +
        "con sincera curiosità. Questa passione mi ha portato a conseguire " +
        "il Diploma di Perito Informatico nel 2019. " +
        "Da allora non mi sono mai fermato: sono entrato in Logit Consulting, " +
        "dove ho sviluppato competenze avanzate nel Cloud Computing. " +
        "Non mi pongo limiti, ma obiettivi da raggiungere, e la mia voglia di crescere " +
        "mi spinge a migliorarmi costantemente."
    },

    sidebar: {
      download: "⬇ Scarica CV (PDF)",

      languages: {
        title: "Lingue",
        it: {
          label: "🇮🇹 Italiano",
          level: "Madrelingua"
        },
        en: {
          label: "🇬🇧 Inglese",
          level: "B1"
        }
      },

      driving: {
        title: "Licenze di guida"
      }
    },

    experience: {
      title: "Esperienza",

      logit: {
        role: "Senior AWS Solution Architect – Referente Area Cloud",
        period: "Logit Consulting srl · 2019 - Presente",
        b1: "Progettazione, creazione e mantenimento di ambienti cloud scalabili, resilienti e facilmente gestibili",
        b2: "Progettazione di ambienti basati su Kubernetes e gestiti tramite pipeline CI/CD",
        b3: "Progettazione di sistemi di monitoraggio versatili e adattabili a diversi contesti infrastrutturali"
      },

      intern1: {
        role: "Stagista",
        period: "Sirius srl · Gennaio 2018 - Febbraio 2018",
        b1: "Creazione di bot Telegram per la gestione delle notifiche"
      },

      intern2: {
        role: "Stagista",
        period: "Adient Italy srl · Giugno 2017 - Luglio 2017",
        b1: "Automatizzazione del sistema di gestione del registro ospiti"
      }
    },

    education: {
      title: "Formazione",

      diploma: {
        role: "Diploma di Perito Informatico",
        period: "I.I.S. G. Peano · 2014 - 2019",
        b1: "Basi di utilizzo dei sistemi e implementazione di reti di calcolatori",
        b2: "Basi di programmazione informatica",
        b3: "Basi di tecniche di progettazione di sistemi"
      }
    },

    certifications: {
      title: "Certificazioni"
    },

    projects: {
      title: "Progetti",

      rpi: {
        title: "Raspberry Pi Clock & Weather",
        desc:
          "Progetto basato su Raspberry Pi per la visualizzazione di orario, " +
          "meteo e statistiche di sistema su display OLED e TFT, " +
          "con integrazione di sensori e script Python."
      },

      terraform: {
        title: "Stack Terraform per Siti Statici",
        desc:
          "Infrastruttura Terraform per il deploy di siti statici su AWS " +
          "utilizzando S3, CloudFront, ACM e Route53. "
      }
    }
  },

  en: {
    hero: {
      name: "Marco Cavalieri",
      role: "IT Consultant"
    },

    nav: {
      profile: "Profile",
      experience: "Experience",
      education: "Education",
      certifications: "Certifications",
      projects: "Projects"
    },

    profile: {
      title: "Profile",
      text:
        "Hi! I'm Marco, born in 2000 and a technology enthusiast with a strong passion for IT. " +
        "I've been curious about computers since I was a child, a passion that led me " +
        "to earn my IT Technician diploma in 2019. " +
        "Since then, I have never stopped growing: I joined Logit Consulting, " +
        "where I developed solid expertise in Cloud Computing. " +
        "I don't set limits for myself, only goals to achieve, " +
        "and my will to improve pushes me forward every day."
    },

     sidebar: {
      download: "⬇ Download CV (PDF)",
    
      languages: {
        title: "Languages",
        it: {
          label: "🇮🇹 Italian",
          level: "Native"
        },
        en: {
          label: "🇬🇧 English",
          level: "Intermediate (B1)"
        }
      },
  
      driving: {
        title: "Driving Licenses"
      }
    },   

    experience: {
      title: "Experience",

      logit: {
        role: "Senior AWS Solution Architect – Cloud Area Lead",
        period: "Logit Consulting srl · 2019 - Present",
        b1: "Design, implementation and maintenance of scalable and resilient cloud environments",
        b2: "Design of Kubernetes-based platforms managed through CI/CD pipelines",
        b3: "Design of flexible monitoring systems adaptable to multiple infrastructure scenarios"
      },

      intern1: {
        role: "Intern",
        period: "Sirius srl · January 2018 - February 2018",
        b1: "Development of Telegram bots for notification management"
      },

      intern2: {
        role: "Intern",
        period: "Adient Italy srl · June 2017 - July 2017",
        b1: "Automation of the guest registration management system"
      }
    },

    education: {
      title: "Education",

      diploma: {
        role: "IT Technician Diploma",
        period: "I.I.S. G. Peano · 2014 - 2019",
        b1: "Fundamentals of operating systems and computer networks",
        b2: "Fundamentals of software development",
        b3: "Fundamentals of system design techniques"
      }
    },

    certifications: {
      title: "Certifications"
    },

    projects: {
      title: "Projects",

      rpi: {
        title: "Raspberry Pi Clock & Weather",
        desc:
          "Raspberry Pi-based project for displaying time, weather and system statistics " +
          "on OLED and TFT displays, with sensors integration and Python scripts."
      },

      terraform: {
        title: "Terraform Stack for Static Websites",
        desc:
          "Terraform infrastructure for deploying static websites on AWS using " +
          "S3, CloudFront, ACM and Route53."
      }
    }
  }
};


function translatePage(lang) {
  document.querySelectorAll("[data-i18n]").forEach(el => {
    const keys = el.dataset.i18n.split(".");
    let value = translations[lang];

    keys.forEach(k => {
      value = value?.[k];
    });

    if (value) el.textContent = value;
  });

  currentLang = lang;
}

document.getElementById("langToggle").addEventListener("click", () => {
  const next = currentLang === "it" ? "en" : "it";
  translatePage(next);
  document.getElementById("langToggle").textContent =
    next === "it" ? "🇬🇧 EN" : "🇮🇹 IT";
});

translatePage("it");
