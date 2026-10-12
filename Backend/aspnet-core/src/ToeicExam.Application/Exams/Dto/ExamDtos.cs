using System;
using System.Collections.Generic;

namespace ToeicExam.Exams.Dto;

public class ExamListDto
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public int DurationMinutes { get; set; }
    public int TotalQuestions { get; set; }
    public string? Description { get; set; }
    public DateTime CreationTime { get; set; }
    public int TotalAttempts { get; set; }
}

public class ExamDetailDto
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public int DurationMinutes { get; set; }
    public int TotalQuestions { get; set; }
    public List<PartDetailDto> Parts { get; set; } = new();
}

public class PartDetailDto
{
    public int Id { get; set; }
    public int PartNumber { get; set; }
    public string Name { get; set; } = string.Empty;
    public int QuestionStart { get; set; }
    public int QuestionEnd { get; set; }
    public List<GroupDetailDto> Groups { get; set; } = new();
}

public class GroupDetailDto
{
    public int Id { get; set; }
    public string? GroupCode { get; set; }
    public string? GroupTitle { get; set; }
    public string? PassageText { get; set; }
    public string? ImageUrl { get; set; }
    public int OrderIndex { get; set; }
    public List<QuestionDetailDto> Questions { get; set; } = new();
}

public class QuestionDetailDto
{
    public int Id { get; set; }
    public int QuestionNumber { get; set; }
    public string Content { get; set; } = string.Empty;
    public string? CorrectOption { get; set; } // Only visible to admin, hidden for user during exam
    public int OrderIndex { get; set; }
    public List<OptionDetailDto> Options { get; set; } = new();
}

public class OptionDetailDto
{
    public int Id { get; set; }
    public string OptionLabel { get; set; } = string.Empty; // A, B, C, D
    public string Content { get; set; } = string.Empty;
}

public class SubmitExamInput
{
    public int ExamId { get; set; }
    public string? StudentName { get; set; }
    public string? StudentCode { get; set; }
    public List<UserAnswerInput> Answers { get; set; } = new();
}

public class UserAnswerInput
{
    public int QuestionId { get; set; }
    public int QuestionNumber { get; set; }
    public string? SelectedOption { get; set; } // A, B, C, D or null
}

public class ExamResultDto
{
    public int AttemptId { get; set; }
    public int ExamId { get; set; }
    public string ExamTitle { get; set; } = string.Empty;
    public string? StudentName { get; set; }
    public int TotalCorrect { get; set; }
    public int TotalWrong { get; set; }
    public int TotalSkipped { get; set; }
    public int TotalQuestions { get; set; }
    public int EstimatedScore { get; set; }
    public double AccuracyPercentage { get; set; }
    public List<QuestionResultDetailDto> Details { get; set; } = new();
}

public class QuestionResultDetailDto
{
    public int QuestionId { get; set; }
    public int QuestionNumber { get; set; }
    public string QuestionContent { get; set; } = string.Empty;
    public string? SelectedOption { get; set; }
    public string CorrectOption { get; set; } = string.Empty;
    public bool IsCorrect { get; set; }
}

public class EditQuestionInput
{
    public int QuestionId { get; set; }
    public string Content { get; set; } = string.Empty;
    public string CorrectOption { get; set; } = string.Empty;
    public string? PassageText { get; set; }
    public Dictionary<string, string> Options { get; set; } = new();
}
