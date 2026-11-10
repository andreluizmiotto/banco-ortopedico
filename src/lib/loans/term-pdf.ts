import "server-only";
import { PDFDocument, StandardFonts, rgb } from "pdf-lib";

export type LoanTermPdfInput = {
  modelBody: string;
  modelVersion: number;
  reviewStatus: "pending_legal_review" | "approved";
  values: Record<string, string>;
};

const pageWidth = 595.28;
const pageHeight = 841.89;
const margin = 56;
const lineHeight = 16;
const bodySize = 11;
const maxLineLength = 88;

export async function renderLoanTermPdf(
  input: LoanTermPdfInput,
): Promise<Uint8Array> {
  const document = await PDFDocument.create();
  const font = await document.embedFont(StandardFonts.Helvetica);
  const bold = await document.embedFont(StandardFonts.HelveticaBold);

  document.setTitle("Termo de empréstimo");
  document.setAuthor("");
  document.setSubject("");
  document.setKeywords([]);
  document.setProducer("");
  document.setCreator("");
  document.setCreationDate(new Date(0));
  document.setModificationDate(new Date(0));

  const text = fillModel(input.modelBody, input.values);
  const lines = wrapText(text, maxLineLength);

  let page = document.addPage([pageWidth, pageHeight]);
  let cursor = pageHeight - margin;

  for (const line of lines) {
    if (cursor < margin + 40) {
      page = document.addPage([pageWidth, pageHeight]);
      cursor = pageHeight - margin;
    }

    const isHeading = line.length > 0 && line === line.toUpperCase() && line.length < 60;
    page.drawText(line, {
      x: margin,
      y: cursor,
      size: isHeading ? bodySize + 1 : bodySize,
      font: isHeading ? bold : font,
      color: rgb(0.33, 0.34, 0.35),
      maxWidth: pageWidth - margin * 2,
    });
    cursor -= lineHeight;
  }

  if (input.reviewStatus === "pending_legal_review") {
    const footer =
      `Modelo provisório — versão ${input.modelVersion} — pendente de revisão jurídica`;
    for (const current of document.getPages()) {
      current.drawText(footer, {
        x: margin,
        y: margin / 2,
        size: 9,
        font,
        color: rgb(0.33, 0.34, 0.35),
      });
    }
  }

  return document.save();
}

function fillModel(body: string, values: Record<string, string>): string {
  return body.replace(/\{([a-z_]+)\}/g, (match, key: string) => {
    const value = values[key];
    return value === undefined ? match : value;
  });
}

function wrapText(text: string, limit: number): string[] {
  const lines: string[] = [];

  for (const paragraph of text.split("\n")) {
    if (paragraph.trim() === "") {
      lines.push("");
      continue;
    }

    let current = "";
    for (const word of paragraph.split(/\s+/)) {
      if (current === "") {
        current = word;
      } else if (current.length + 1 + word.length <= limit) {
        current = `${current} ${word}`;
      } else {
        lines.push(current);
        current = word;
      }
    }
    if (current !== "") lines.push(current);
  }

  return lines;
}
