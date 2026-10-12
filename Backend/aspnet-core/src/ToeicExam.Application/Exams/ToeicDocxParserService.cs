using System;
using System.Collections.Generic;
using System.IO;
using System.IO.Compression;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Xml.Linq;
using Microsoft.EntityFrameworkCore;
using ToeicExam.EntityFrameworkCore;
using ToeicExam.Exams;

namespace ToeicExam.Exams;

public class DocxParseResult
{
    public bool IsSuccess { get; set; }
    public List<string> Errors { get; set; } = new();
    public List<string> Warnings { get; set; } = new();
    public Exam? CreatedTest { get; set; }
    public int TotalQuestionsParsed { get; set; }
    public int TotalPartsParsed { get; set; }
}

public interface IToeicDocxParserService
{
    Task<DocxParseResult> ParseAndSaveDocxAsync(Stream docxStream, string fileName, bool requireAnswers = true);
    DocxParseResult ValidateDocxContent(string textContent, bool requireAnswers = true);
    DocxParseResult ValidateDocxStream(Stream docxStream, bool requireAnswers = true);
}

public class ToeicDocxParserService : IToeicDocxParserService
{
    private readonly ToeicExamDbContext _dbContext;

    public ToeicDocxParserService(ToeicExamDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<DocxParseResult> ParseAndSaveDocxAsync(Stream docxStream, string fileName, bool requireAnswers = true)
    {
        string textContent;
        try
        {
            textContent = ExtractTextFromDocx(docxStream);
        }
        catch (Exception ex)
        {
            return new DocxParseResult
            {
                IsSuccess = false,
                Errors = new List<string> { $"Không thể đọc file Word: {ex.Message}. Hãy chắc chắn file đúng định dạng .docx." }
            };
        }

        var validation = ValidateDocxContent(textContent, requireAnswers);
        if (!validation.IsSuccess)
        {
            return validation; // Rollback, do not save to DB!
        }

        try
        {
            var exam = validation.CreatedTest!;
            await _dbContext.Exams.AddAsync(exam);
            await _dbContext.SaveChangesAsync();

            return new DocxParseResult
            {
                IsSuccess = true,
                CreatedTest = exam,
                TotalQuestionsParsed = validation.TotalQuestionsParsed,
                TotalPartsParsed = validation.TotalPartsParsed,
                Warnings = validation.Warnings
            };
        }
        catch (Exception ex)
        {
            return new DocxParseResult
            {
                IsSuccess = false,
                Errors = new List<string> { $"Lỗi khi lưu vào cơ sở dữ liệu: {ex.Message}" }
            };
        }
    }

    public DocxParseResult ValidateDocxStream(Stream docxStream, bool requireAnswers = true)
    {
        string textContent;
        try
        {
            textContent = ExtractTextFromDocx(docxStream);
        }
        catch (Exception ex)
        {
            return new DocxParseResult
            {
                IsSuccess = false,
                Errors = new List<string> { $"Không thể đọc file Word: {ex.Message}. Hãy chắc chắn file đúng định dạng .docx." }
            };
        }

        return ValidateDocxContent(textContent, requireAnswers);
    }

    public DocxParseResult ValidateDocxContent(string textContent, bool requireAnswers = true)
    {
        var result = new DocxParseResult();
        var lines = textContent.Split(new[] { "\r\n", "\r", "\n" }, StringSplitOptions.None)
                               .Select(l => l.Trim())
                               .Where(l => !string.IsNullOrEmpty(l))
                               .ToList();

        if (lines.Count == 0)
        {
            result.Errors.Add("File Word không có nội dung.");
            result.IsSuccess = false;
            return result;
        }

        // Determine title
        string title = "Đề thi TOEIC Reading";
        var firstLine = lines[0];
        if (!firstLine.StartsWith("<") && !firstLine.StartsWith("["))
        {
            title = firstLine;
        }

        var exam = new Exam
        {
            Title = title,
            DurationMinutes = 75,
            TotalQuestions = 100,
            CreatedAt = DateTime.Now
        };

        // Extract Answer Key map if present
        var answerKeyMap = new Dictionary<int, string>();
        var keyMatches = Regex.Matches(textContent, @"<KEY\s+question=[""'](\d+)[""']\s+answer=[""']([A-D])[""']\s*/>", RegexOptions.IgnoreCase);
        foreach (Match km in keyMatches)
        {
            if (int.TryParse(km.Groups[1].Value, out int qNum))
            {
                answerKeyMap[qNum] = km.Groups[2].Value.ToUpper();
            }
        }

        // Parse Part blocks
        var partMatches = Regex.Matches(textContent, @"<PART\b([^>]*)>([\s\S]*?)</PART>", RegexOptions.IgnoreCase);
        if (partMatches.Count == 0)
        {
            result.Errors.Add("Không tìm thấy thẻ phân đoạn <PART> trong file. Đề thi phải có ít nhất 1 Part (ví dụ <PART id=\"5\">...).");
        }

        var allParsedQuestions = new List<Question>();
        int partOrder = 1;

        foreach (Match pm in partMatches)
        {
            string partAttr = pm.Groups[1].Value;
            string partBody = pm.Groups[2].Value;

            int partNum = 5;
            var numMatch = Regex.Match(partAttr, @"id=[""'](\d+)[""']", RegexOptions.IgnoreCase);
            if (numMatch.Success) int.TryParse(numMatch.Groups[1].Value, out partNum);

            string partName = $"Part {partNum}";
            var nameMatch = Regex.Match(partAttr, @"name=[""']([^""']+)[""']", RegexOptions.IgnoreCase);
            if (nameMatch.Success) partName = nameMatch.Groups[1].Value;

            var part = new Part
            {
                PartNumber = partNum,
                PartName = partName
            };

            // Parse groups inside Part
            var groupMatches = Regex.Matches(partBody, @"<QUESTION_GROUP\b([^>]*)>([\s\S]*?)</QUESTION_GROUP>", RegexOptions.IgnoreCase);
            if (groupMatches.Count > 0)
            {
                int groupOrder = 1;
                foreach (Match gm in groupMatches)
                {
                    string groupAttr = gm.Groups[1].Value;
                    string groupBody = gm.Groups[2].Value;

                    string? groupCode = null;
                    var codeMatch = Regex.Match(groupAttr, @"id=[""']([^""']+)[""']", RegexOptions.IgnoreCase);
                    if (codeMatch.Success) groupCode = codeMatch.Groups[1].Value;

                    string? groupTitle = null;
                    var titleMatch = Regex.Match(groupBody, @"<GROUP_TITLE>([\s\S]*?)</GROUP_TITLE>", RegexOptions.IgnoreCase);
                    if (titleMatch.Success) groupTitle = titleMatch.Groups[1].Value.Trim();

                    // Passage text or Document text
                    var passageBuilder = new StringBuilder();
                    var docMatches = Regex.Matches(groupBody, @"<(PASSAGE|DOCUMENT)[^>]*>([\s\S]*?)</\1>", RegexOptions.IgnoreCase);
                    foreach (Match dm in docMatches)
                    {
                        passageBuilder.AppendLine(dm.Groups[2].Value.Trim());
                        passageBuilder.AppendLine();
                    }

                    var qGroup = new QuestionGroup
                    {
                        GroupCode = groupCode,
                        GroupTitle = groupTitle,
                        PassageText = passageBuilder.ToString().Trim(),
                        OrderIndex = groupOrder++
                    };

                    // Questions in this group
                    var parsedQs = ParseQuestionsFromBody(groupBody, answerKeyMap, result, requireAnswers);
                    foreach (var q in parsedQs)
                    {
                        qGroup.Questions.Add(q);
                        allParsedQuestions.Add(q);
                    }

                    part.QuestionGroups.Add(qGroup);
                }
            }
            else
            {
                // Part without explicit groups (e.g., Part 5)
                var defaultGroup = new QuestionGroup
                {
                    GroupCode = $"Part_{partNum}_Single",
                    GroupTitle = partName,
                    OrderIndex = 1
                };

                var parsedQs = ParseQuestionsFromBody(partBody, answerKeyMap, result, requireAnswers);
                foreach (var q in parsedQs)
                {
                    defaultGroup.Questions.Add(q);
                    allParsedQuestions.Add(q);
                }

                part.QuestionGroups.Add(defaultGroup);
            }

            exam.Parts.Add(part);
            partOrder++;
        }

        // Validate Question Numbering Sequence
        if (allParsedQuestions.Count > 0)
        {
            var ordered = allParsedQuestions.OrderBy(q => q.QuestionNumber).ToList();
            int prevNum = ordered[0].QuestionNumber;
            for (int i = 1; i < ordered.Count; i++)
            {
                int currNum = ordered[i].QuestionNumber;
                if (currNum != prevNum + 1)
                {
                    result.Errors.Add($"Sai thứ tự câu hỏi: Câu hỏi nhảy từ câu {prevNum} sang câu {currNum} (thiếu các câu ở giữa).");
                }
                prevNum = currNum;
            }

            exam.TotalQuestions = allParsedQuestions.Count;
            result.TotalQuestionsParsed = allParsedQuestions.Count;
            result.TotalPartsParsed = exam.Parts.Count;
        }
        else
        {
            result.Errors.Add("Không tìm thấy câu hỏi hợp lệ nào trong file đề thi.");
        }

        if (result.Errors.Count == 0)
        {
            result.IsSuccess = true;
            result.CreatedTest = exam;
        }
        else
        {
            result.IsSuccess = false;
        }

        return result;
    }

    private List<Question> ParseQuestionsFromBody(string body, Dictionary<int, string> answerKeyMap, DocxParseResult result, bool requireAnswers)
    {
        var list = new List<Question>();
        var qMatches = Regex.Matches(body, @"<QUESTION\b([^>]*)>([\s\S]*?)</QUESTION>", RegexOptions.IgnoreCase);

        int order = 1;
        foreach (Match qm in qMatches)
        {
            string qAttr = qm.Groups[1].Value;
            string qBody = qm.Groups[2].Value;

            var idMatch = Regex.Match(qAttr, @"id=[""'](\d+)[""']", RegexOptions.IgnoreCase);
            if (!idMatch.Success)
            {
                result.Errors.Add("Phát hiện thẻ <QUESTION> thiếu thuộc tính id=\"[số thứ tự câu]\"");
                continue;
            }

            int qNum = int.Parse(idMatch.Groups[1].Value);

            // Stem
            string stem = "";
            var stemMatch = Regex.Match(qBody, @"<STEM>([\s\S]*?)</STEM>", RegexOptions.IgnoreCase);
            if (stemMatch.Success)
            {
                stem = stemMatch.Groups[1].Value.Trim();
            }
            else
            {
                result.Errors.Add($"Câu hỏi {qNum} thiếu thẻ nội dung câu hỏi <STEM>...</STEM>.");
            }

            // Options
            var optMatches = Regex.Matches(qBody, @"<OPTION\s+label=[""']([A-D])[""']>([\s\S]*?)</OPTION>", RegexOptions.IgnoreCase);
            var optionsList = new List<QuestionOption>();
            foreach (Match om in optMatches)
            {
                string label = om.Groups[1].Value.ToUpper();
                string optContent = om.Groups[2].Value.Trim();
                optionsList.Add(new QuestionOption
                {
                    Label = label,
                    Content = optContent
                });
            }

            if (optionsList.Count < 4)
            {
                result.Errors.Add($"Câu hỏi {qNum} không đủ 4 lựa chọn đáp án (A, B, C, D). Chỉ tìm thấy {optionsList.Count} lựa chọn.");
            }

            // Correct Answer
            string correctAnswer = "";
            var ansMatch = Regex.Match(qBody, @"<ANSWER>([A-D])</ANSWER>", RegexOptions.IgnoreCase);
            if (ansMatch.Success)
            {
                correctAnswer = ansMatch.Groups[1].Value.ToUpper();
            }
            else if (answerKeyMap.TryGetValue(qNum, out string? keyAns))
            {
                correctAnswer = keyAns;
            }
            else
            {
                // check correct="true" attribute on option
                var correctOptMatch = Regex.Match(qBody, @"<OPTION\s+[^>]*correct=[""']true[""'][^>]*label=[""']([A-D])[""']", RegexOptions.IgnoreCase);
                if (correctOptMatch.Success)
                {
                    correctAnswer = correctOptMatch.Groups[1].Value.ToUpper();
                }
            }

            if (string.IsNullOrEmpty(correctAnswer))
            {
                if (requireAnswers)
                {
                    result.Errors.Add($"Câu hỏi {qNum} thiếu đáp án đúng (<ANSWER>A/B/C/D</ANSWER>).");
                }
                else
                {
                    result.Warnings.Add($"Câu hỏi {qNum} chưa có đáp án đúng.");
                    correctAnswer = "A"; // default fallback for preview if strict mode disabled
                }
            }

            var question = new Question
            {
                QuestionNumber = qNum,
                QuestionStem = stem,
                CorrectAnswer = correctAnswer,
                OrderIndex = order++,
                Options = optionsList
            };

            list.Add(question);
        }

        return list;
    }

    private string ExtractTextFromDocx(Stream docxStream)
    {
        var sb = new StringBuilder();
        using (var archive = new ZipArchive(docxStream, ZipArchiveMode.Read, true))
        {
            var documentEntry = archive.GetEntry("word/document.xml");
            if (documentEntry == null)
            {
                throw new InvalidOperationException("Không tìm thấy tệp word/document.xml trong file .docx.");
            }

            using (var entryStream = documentEntry.Open())
            {
                var doc = XDocument.Load(entryStream);
                XNamespace w = "http://schemas.openxmlformats.org/wordprocessingml/2006/main";

                foreach (var p in doc.Descendants(w + "p"))
                {
                    var text = string.Join("", p.Descendants(w + "t").Select(t => t.Value));
                    if (!string.IsNullOrWhiteSpace(text))
                    {
                        sb.AppendLine(text);
                    }
                }
            }
        }
        return sb.ToString();
    }
}
