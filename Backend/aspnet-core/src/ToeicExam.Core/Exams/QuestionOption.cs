using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ToeicExam.Exams;

[Table("QuestionOptions")]
public class QuestionOption
{
    [Key]
    public int Id { get; set; }

    public int QuestionId { get; set; }

    [ForeignKey(nameof(QuestionId))]
    public virtual Question Question { get; set; } = null!;

    [Required]
    [MaxLength(5)]
    public string Label { get; set; } = string.Empty; // A, B, C, D

    [Required]
    public string Content { get; set; } = string.Empty;
}
