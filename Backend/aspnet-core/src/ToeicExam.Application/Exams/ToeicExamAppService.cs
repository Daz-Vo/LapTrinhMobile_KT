using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.EntityFrameworkCore;
using ToeicExam.EntityFrameworkCore;
using ToeicExam.Exams.Dto;

namespace ToeicExam.Exams;

public interface IToeicExamAppService
{
    Task<List<ExamListDto>> GetAllExamsAsync();
    Task<ExamDetailDto> GetExamForStudentAsync(int id);
    Task<ExamDetailDto> GetExamForAdminAsync(int id);
    Task<ExamResultDto> SubmitExamAsync(SubmitExamInput input);
    Task<ExamResultDto?> GetLatestAttemptAsync(string? studentCode = null);
    Task UpdateQuestionAsync(EditQuestionInput input);
    Task DeleteExamAsync(int id);
}

public class ToeicExamAppService : IToeicExamAppService
{
    private readonly ToeicExamDbContext _db;

    public ToeicExamAppService(ToeicExamDbContext db)
    {
        _db = db;
    }

    public async Task<List<ExamListDto>> GetAllExamsAsync()
    {
        var exams = await _db.Exams
            .OrderByDescending(e => e.CreatedAt)
            .ToListAsync();

        return exams.Select(e => new ExamListDto
        {
            Id = e.Id,
            Title = e.Title,
            DurationMinutes = e.DurationMinutes,
            TotalQuestions = e.TotalQuestions,
            Description = $"Bộ đề gồm {e.TotalQuestions} câu TOEIC Reading",
            CreationTime = e.CreatedAt ?? DateTime.Now,
            TotalAttempts = 0
        }).ToList();
    }

    public async Task<ExamDetailDto> GetExamForStudentAsync(int id)
    {
        return await GetExamInternalAsync(id, isAdmin: false);
    }

    public async Task<ExamDetailDto> GetExamForAdminAsync(int id)
    {
        return await GetExamInternalAsync(id, isAdmin: true);
    }

    private async Task<ExamDetailDto> GetExamInternalAsync(int id, bool isAdmin)
    {
        var exam = await _db.Exams
            .Include(e => e.Parts)
                .ThenInclude(p => p.QuestionGroups)
                    .ThenInclude(g => g.Questions)
                        .ThenInclude(q => q.Options)
            .FirstOrDefaultAsync(e => e.Id == id);

        if (exam == null)
        {
            throw new KeyNotFoundException($"Không tìm thấy đề thi có Id = {id}");
        }

        var dto = new ExamDetailDto
        {
            Id = exam.Id,
            Title = exam.Title,
            DurationMinutes = exam.DurationMinutes,
            TotalQuestions = exam.TotalQuestions,
            Parts = exam.Parts.OrderBy(p => p.PartNumber).Select(p =>
            {
                var qList = p.QuestionGroups.SelectMany(g => g.Questions).ToList();
                int qStart = qList.Count > 0 ? qList.Min(q => q.QuestionNumber) : 0;
                int qEnd = qList.Count > 0 ? qList.Max(q => q.QuestionNumber) : 0;

                return new PartDetailDto
                {
                    Id = p.Id,
                    PartNumber = p.PartNumber,
                    Name = p.PartName,
                    QuestionStart = qStart,
                    QuestionEnd = qEnd,
                    Groups = p.QuestionGroups.OrderBy(g => g.OrderIndex).Select(g => new GroupDetailDto
                    {
                        Id = g.Id,
                        GroupCode = g.GroupCode,
                        GroupTitle = g.GroupTitle,
                        PassageText = g.PassageText,
                        ImageUrl = g.ImageUrl,
                        OrderIndex = g.OrderIndex,
                        Questions = g.Questions.OrderBy(q => q.QuestionNumber).Select(q => new QuestionDetailDto
                        {
                            Id = q.Id,
                            QuestionNumber = q.QuestionNumber,
                            Content = q.QuestionStem,
                            CorrectOption = isAdmin ? q.CorrectAnswer : null,
                            OrderIndex = q.OrderIndex,
                            Options = q.Options.OrderBy(o => o.Label).Select(o => new OptionDetailDto
                            {
                                Id = o.Id,
                                OptionLabel = o.Label,
                                Content = o.Content
                            }).ToList()
                        }).ToList()
                    }).ToList()
                };
            }).ToList()
        };

        return dto;
    }

    public async Task<ExamResultDto> SubmitExamAsync(SubmitExamInput input)
    {
        var exam = await _db.Exams
            .Include(e => e.Parts)
                .ThenInclude(p => p.QuestionGroups)
                    .ThenInclude(g => g.Questions)
            .FirstOrDefaultAsync(e => e.Id == input.ExamId);

        if (exam == null)
        {
            throw new KeyNotFoundException($"Không tìm thấy đề thi có Id = {input.ExamId}");
        }

        var allQuestions = exam.Parts
            .SelectMany(p => p.QuestionGroups)
            .SelectMany(g => g.Questions)
            .ToDictionary(q => q.QuestionNumber);

        var answerInputMap = input.Answers
            .GroupBy(a => a.QuestionNumber)
            .ToDictionary(g => g.Key, g => g.Last().SelectedOption?.Trim().ToUpper());

        int correctCount = 0;
        int wrongCount = 0;
        int skippedCount = 0;

        var details = new List<QuestionResultDetailDto>();

        foreach (var kv in allQuestions.OrderBy(x => x.Key))
        {
            int qNum = kv.Key;
            var q = kv.Value;

            answerInputMap.TryGetValue(qNum, out string? selected);
            bool isAnswered = !string.IsNullOrEmpty(selected);

            bool isCorrect = false;
            if (!isAnswered)
            {
                skippedCount++;
            }
            else
            {
                if (string.Equals(selected, q.CorrectAnswer, StringComparison.OrdinalIgnoreCase))
                {
                    isCorrect = true;
                    correctCount++;
                }
                else
                {
                    wrongCount++;
                }
            }

            details.Add(new QuestionResultDetailDto
            {
                QuestionId = q.Id,
                QuestionNumber = qNum,
                QuestionContent = q.QuestionStem,
                SelectedOption = selected,
                CorrectOption = q.CorrectAnswer,
                IsCorrect = isCorrect
            });
        }

        int totalQuestions = allQuestions.Count;
        int finalScore = CalculateToeicReadingScore(correctCount, totalQuestions);

        return new ExamResultDto
        {
            AttemptId = 1,
            ExamId = exam.Id,
            ExamTitle = exam.Title,
            StudentName = input.StudentName ?? "Thí sinh tự do",
            TotalCorrect = correctCount,
            TotalWrong = wrongCount,
            TotalSkipped = skippedCount,
            TotalQuestions = totalQuestions,
            EstimatedScore = finalScore,
            AccuracyPercentage = totalQuestions > 0 ? Math.Round((double)correctCount / totalQuestions * 100, 1) : 0,
            Details = details
        };
    }

    public Task<ExamResultDto?> GetLatestAttemptAsync(string? studentCode = null)
    {
        return Task.FromResult<ExamResultDto?>(null);
    }

    public async Task UpdateQuestionAsync(EditQuestionInput input)
    {
        var question = await _db.Questions
            .Include(q => q.Options)
            .Include(q => q.Group)
            .FirstOrDefaultAsync(q => q.Id == input.QuestionId);

        if (question == null)
        {
            throw new KeyNotFoundException($"Không tìm thấy câu hỏi Id = {input.QuestionId}");
        }

        question.QuestionStem = input.Content;
        if (!string.IsNullOrEmpty(input.CorrectOption))
        {
            question.CorrectAnswer = input.CorrectOption.ToUpper();
        }

        if (input.PassageText != null && question.Group != null)
        {
            question.Group.PassageText = input.PassageText;
        }

        if (input.Options != null)
        {
            foreach (var opt in question.Options)
            {
                if (input.Options.TryGetValue(opt.Label, out string? newContent))
                {
                    opt.Content = newContent;
                }
            }
        }

        await _db.SaveChangesAsync();
    }

    public async Task DeleteExamAsync(int id)
    {
        await _db.Database.ExecuteSqlRawAsync(@"
            DELETE FROM QuestionOptions WHERE QuestionId IN (
                SELECT q.Id 
                FROM Questions q
                INNER JOIN QuestionGroups g ON q.GroupId = g.Id
                INNER JOIN Parts p ON g.PartId = p.Id
                WHERE p.ExamId = {0}
            );
            DELETE FROM Questions WHERE GroupId IN (
                SELECT g.Id 
                FROM QuestionGroups g
                INNER JOIN Parts p ON g.PartId = p.Id
                WHERE p.ExamId = {0}
            );
            DELETE FROM QuestionGroups WHERE PartId IN (
                SELECT Id FROM Parts WHERE ExamId = {0}
            );
            DELETE FROM Parts WHERE ExamId = {0};
            DELETE FROM Exams WHERE Id = {0};
        ", id);
    }

    private int CalculateToeicReadingScore(int correct, int total)
    {
        if (total == 0 || correct == 0) return 5;
        double ratio = (double)correct / total;
        int scaled = (int)Math.Round(5 + (ratio * 490));
        scaled = (int)(Math.Round((double)scaled / 5) * 5);
        return Math.Clamp(scaled, 5, 495);
    }
}
