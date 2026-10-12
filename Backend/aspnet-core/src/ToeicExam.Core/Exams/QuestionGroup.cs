using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ToeicExam.Exams;

[Table("QuestionGroups")]
public class QuestionGroup
{
    [Key]
    public int Id { get; set; }

    public int PartId { get; set; }

    [ForeignKey(nameof(PartId))]
    public virtual Part Part { get; set; } = null!;

    [MaxLength(50)]
    public string? GroupCode { get; set; } // Ví dụ: QG-131-134

    [MaxLength(250)]
    public string? GroupTitle { get; set; }

    public string? PassageText { get; set; }

    [MaxLength(500)]
    public string? ImageUrl { get; set; }

    public int OrderIndex { get; set; } = 1;

    public virtual ICollection<Question> Questions { get; set; } = new List<Question>();
}
