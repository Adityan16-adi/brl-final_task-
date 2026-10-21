import { useLanguage } from "./useLanguage.js";

export default function LocalizedText({ text }) {
  const { language, t } = useLanguage();
  if (language === "hi" && /^\d+(?:\.\d+)?%?$/.test(text)) {
    const percentage = text.endsWith("%");
    const value = Number(percentage ? text.slice(0, -1) : text);
    return `${new Intl.NumberFormat("hi-IN").format(value)}${percentage ? "%" : ""}`;
  }
  return t(text);
}
