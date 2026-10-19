import { useContext } from "react";
import { LanguageContext } from "./languageContext.js";

export function useLanguage() {
  const context = useContext(LanguageContext);
  if (!context) throw new Error("useLanguage must be used inside LanguageProvider.");
  return context;
}

export function useLocalizedNumber() {
  const { language } = useLanguage();
  const locale = language === "hi" ? "hi-IN" : "en-IN";
  return (value, options) => new Intl.NumberFormat(locale, options).format(value);
}

export function useLocalizedDate() {
  const { language } = useLanguage();
  const locale = language === "hi" ? "hi-IN" : "en-IN";
  return (value, options) => {
    const date = /^\d{4}-\d{2}-\d{2}$/.test(value) ? new Date(`${value}T00:00:00`) : new Date(value);
    return new Intl.DateTimeFormat(locale, options).format(date);
  };
}
