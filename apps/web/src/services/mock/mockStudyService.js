// Frontend-only study responses and questions are predefined.
const questions = [
  { prompt: "Which cell structure is most associated with releasing usable energy?", options: ["Mitochondrion", "Ribosome", "Cell wall", "Vacuole"], answer: 0 },
  { prompt: "What is the main role of a cell membrane?", options: ["Store genetic information", "Control what enters and leaves", "Build proteins", "Release oxygen"], answer: 1 },
  { prompt: "Where is most genetic information in an animal cell stored?", options: ["Cytoplasm", "Golgi apparatus", "Nucleus", "Lysosome"], answer: 2 },
];

export async function askMentor(prompt) {
  const normalizedPrompt = prompt.toLowerCase();
  const subjectKey = normalizedPrompt.includes("algebra") || normalizedPrompt.includes("बीजगणित") ? "Mathematics" : "Cell structures";
  return {
    responseKey: "Let’s break that down. For {{subject}}, start by naming the main idea, then connect it to one example from your lesson. What part feels least clear right now?",
    subjectKey,
  };
}
export async function generateQuiz({ count = 3 }) {
  return { questions: questions.slice(0, Math.min(Number(count), questions.length)).map((question) => ({ ...question, options: [...question.options] })) };
}
export async function checkMessage(text) {
  const flagged = /free money|click this link|buy now/i.test(text);
  return { flagged, reason: flagged ? "This phrase matches a sample review rule." : "No sample review flags found." };
}