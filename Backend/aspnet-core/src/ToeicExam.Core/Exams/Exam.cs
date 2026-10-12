using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace ToeicExam.Exams;

[Table("Exams")]
public class Exam
{
    [Key]
    public int Id { get; set; }

    [Required]
    [MaxLength(250)]
    public string Title { get; set; } = string.Empty;

    public int DurationMinutes { get; set; } = 75;

    public int TotalQuestions { get; set; } = 100;

    public DateTime? CreatedAt { get; set; } = DateTime.Now;

    public virtual ICollection<Part> Parts { get; set; } = new List<Part>();
}
