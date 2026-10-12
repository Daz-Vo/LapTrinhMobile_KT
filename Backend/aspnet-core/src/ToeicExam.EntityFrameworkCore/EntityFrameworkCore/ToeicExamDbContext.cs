using Microsoft.EntityFrameworkCore;
using ToeicExam.Exams;

namespace ToeicExam.EntityFrameworkCore;

public class ToeicExamDbContext : DbContext
{
    public ToeicExamDbContext(DbContextOptions<ToeicExamDbContext> options)
        : base(options)
    {
    }

    public virtual DbSet<Exam> Exams { get; set; } = null!;
    public virtual DbSet<Part> Parts { get; set; } = null!;
    public virtual DbSet<QuestionGroup> QuestionGroups { get; set; } = null!;
    public virtual DbSet<Question> Questions { get; set; } = null!;
    public virtual DbSet<QuestionOption> QuestionOptions { get; set; } = null!;

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.Entity<Exam>(b =>
        {
            b.ToTable("Exams");
            b.HasKey(e => e.Id);
            b.Property(e => e.Title).HasMaxLength(250).IsRequired();
            b.Property(e => e.DurationMinutes).HasDefaultValue(75);
            b.Property(e => e.TotalQuestions).HasDefaultValue(100);
            b.Property(e => e.CreatedAt).HasDefaultValueSql("GETDATE()");
        });

        modelBuilder.Entity<Part>(b =>
        {
            b.ToTable("Parts");
            b.HasKey(p => p.Id);
            b.HasOne(p => p.Exam)
             .WithMany(e => e.Parts)
             .HasForeignKey(p => p.ExamId)
             .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<QuestionGroup>(b =>
        {
            b.ToTable("QuestionGroups");
            b.HasKey(g => g.Id);
            b.HasOne(g => g.Part)
             .WithMany(p => p.QuestionGroups)
             .HasForeignKey(g => g.PartId)
             .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Question>(b =>
        {
            b.ToTable("Questions");
            b.HasKey(q => q.Id);
            b.Property(q => q.CorrectAnswer).HasMaxLength(5);
            b.HasOne(q => q.Group)
             .WithMany(g => g.Questions)
             .HasForeignKey(q => q.GroupId)
             .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<QuestionOption>(b =>
        {
            b.ToTable("QuestionOptions");
            b.HasKey(o => o.Id);
            b.Property(o => o.Label).HasMaxLength(5);
            b.HasOne(o => o.Question)
             .WithMany(q => q.Options)
             .HasForeignKey(o => o.QuestionId)
             .OnDelete(DeleteBehavior.Cascade);
        });
    }
}
