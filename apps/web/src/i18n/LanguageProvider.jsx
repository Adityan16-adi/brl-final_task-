import { useEffect, useState } from "react";
import { LanguageContext } from "./languageContext.js";
import { translate } from "./translations.js";

const LANGUAGE_KEY = "unified-learn-language";

export function LanguageProvider({ children }) {
  const [language, setLanguage] = useState(() => {
    try {
      return window.localStorage.getItem(LANGUAGE_KEY) === "hi" ? "hi" : "en";
    } catch {
      return "en";
    }
  });

  useEffect(() => {
    document.documentElement.lang = language;
    document.title = language === "hi"
      ? "यूनिफाइड लर्न · सीखें। बढ़ें। आगे बढ़ें।"
      : "Unified Learn · Learn. Grow. Achieve.";
    const description = document.querySelector('meta[name="description"]');
    if (description) {
      description.setAttribute("content", language === "hi"
        ? "यूनिफाइड लर्न पर लाइव कक्षाएँ, अध्ययन सामग्री और शैक्षणिक काम एक ही जगह व्यवस्थित करें।"
        : "Unified Learn brings classes, learning resources, and academic work together.");
    }
    try {
      window.localStorage.setItem(LANGUAGE_KEY, language);
    } catch {
      // The selected language remains active for this page when storage is unavailable.
    }
  }, [language]);

  function t(key, values) {
    return translate(language, key, values);
  }

  return <LanguageContext.Provider value={{ language, setLanguage, t }}>{children}</LanguageContext.Provider>;
}
