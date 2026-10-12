using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ToeicExam.Exams;

[Table("Parts")]
public class Part
{
    [Key]
    public int Id { get; set; }

    public int ExamId { get; set; }

    [ForeignKey(nameof(ExamId))]
    public virtual Exam Exam { get; set; } = null!;

    public int PartNumber { get; set; } // 5, 6, 7

    [Required]
    [MaxLength(150)]
    public string PartName { get; set; } = string.Empty;

    public virtual ICollection<QuestionGroup> QuestionGroups { get; set; } = new List<QuestionGroup>();
}
