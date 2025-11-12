import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import LanguageDetector from 'i18next-browser-languagedetector';

const resources = {
  en: {
    translation: {
      "welcome": "Welcome to Zedin Steam Manager",
      "dashboard": "Dashboard",
      "servers": "Servers",
      "system": "System",
      "settings": "Settings"
    }
  },
  hu: {
    translation: {
      "welcome": "Üdvözöljük a Zedin Steam Manager-ben",
      "dashboard": "Irányítópult",
      "servers": "Szerverek",
      "system": "Rendszer",
      "settings": "Beállítások"
    }
  }
};

i18n
  .use(LanguageDetector)
  .use(initReactI18next)
  .init({
    resources,
    fallbackLng: 'en',
    interpolation: {
      escapeValue: false,
    },
  });

export default i18n;