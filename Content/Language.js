// All visible text lives here, one object per language. The first language is
// the default one: `node scripts/prerender.mjs` writes it into index.html so
// search engines see real content even without running JavaScript.
//
// To add a language, copy the `en` block under a new key (e.g. `fr`) and
// translate the values. The language switch button appears automatically
// when there are two or more languages. Keys must match the data-i18n
// attributes in index.html.
const translations = {
  en: {
    hero: {
      name: "Your Name",
      role: "Your Job Title"
    },

    nav: {
      profile: "Profile",
      experience: "Experience",
      education: "Education",
      projects: "Projects"
    },

    sidebar: {
      contacts: "Contacts"
    },

    profile: {
      title: "Profile",
      text:
        "Write a short introduction about yourself here: who you are, what you do " +
        "and what you are looking for. Two or three sentences are enough."
    },

    experience: {
      title: "Experience",

      job1: {
        role: "Job Title",
        period: "Company Name · 2022 - Present",
        b1: "Describe a responsibility or an achievement",
        b2: "Describe another one, ideally with a measurable result"
      },

      job2: {
        role: "Previous Job Title",
        period: "Previous Company · 2019 - 2022",
        b1: "Describe what you did there"
      }
    },

    education: {
      title: "Education",

      degree: {
        role: "Degree or Diploma",
        period: "School or University · 2014 - 2019",
        b1: "A subject, a thesis or something you are proud of"
      }
    },

    projects: {
      title: "Projects",

      p1: {
        title: "Project One",
        desc: "One or two sentences about the project and the technologies used."
      },

      p2: {
        title: "Project Two",
        desc: "One or two sentences about the project and the technologies used."
      }
    }
  }
};

document.addEventListener("DOMContentLoaded", () => {
  const languages = Object.keys(translations);
  let current = languages[0];

  function translatePage(lang) {
    document.querySelectorAll("[data-i18n]").forEach((el) => {
      const value = el.dataset.i18n
        .split(".")
        .reduce((node, key) => node?.[key], translations[lang]);
      if (value) el.textContent = value;
    });
    current = lang;
    document.documentElement.lang = lang;
  }

  const button = document.getElementById("langToggle");
  const nextLang = () => languages[(languages.indexOf(current) + 1) % languages.length];

  if (button) {
    if (languages.length < 2) {
      button.remove(); // nothing to switch to
    } else {
      button.textContent = nextLang().toUpperCase();
      button.addEventListener("click", () => {
        translatePage(nextLang());
        button.textContent = nextLang().toUpperCase();
      });
    }
  }

  translatePage(current);
});
