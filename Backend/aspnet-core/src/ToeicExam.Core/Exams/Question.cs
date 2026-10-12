using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ToeicExam.Exams;

[Table("Questions")]
public class Question
{
    [Key]
    public int Id { get; set; }

    public int GroupId { get; set; }

    [ForeignKey(nameof(GroupId))]
    public virtual QuestionGroup Group { get; set; } = null!;

    public int QuestionNumber { get; set; } // 101, 102...

    [Required]
    public string QuestionStem { get; set; } = string.Empty;

    [Required]
    [MaxLength(5)]
    public string CorrectAnswer { get; set; } = string.Empty; // A, B, C, D

    public int OrderIndex { get; set; } = 1;

    public virtual ICollection<QuestionOption> Options { get; set; } = new List<QuestionOption>();
}
