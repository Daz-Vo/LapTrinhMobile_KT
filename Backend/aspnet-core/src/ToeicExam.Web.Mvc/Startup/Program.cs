using System;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Builder;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using ToeicExam.EntityFrameworkCore;
using ToeicExam.Exams;

var builder = WebApplication.CreateBuilder(args);

// Add MVC & Razor runtime compilation
builder.Services.AddControllersWithViews()
    .AddRazorRuntimeCompilation();

// Connection String for SQL Server from appsettings.json
var connectionString = builder.Configuration.GetConnectionString("Default")
    ?? throw new InvalidOperationException("Connection string 'Default' was not found in appsettings.json.");

// Add standard EF Core DbContext with only 7 tables
builder.Services.AddDbContext<ToeicExamDbContext>(options =>
{
    options.UseSqlServer(connectionString);
});

// Register services
builder.Services.AddScoped<IToeicExamAppService, ToeicExamAppService>();
builder.Services.AddScoped<IToeicDocxParserService, ToeicDocxParserService>();

// CORS configuration for Flutter
builder.Services.AddCors(options =>
{
    options.AddPolicy("DefaultCorsPolicy", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// Auto-seed Reading_v07.docx if database has 0 exams
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<ToeicExamDbContext>();
    try
    {
        if (!await db.Exams.AnyAsync())
        {
            var parser = scope.ServiceProvider.GetRequiredService<IToeicDocxParserService>();
            string[] candidates = new[]
            {
                Path.GetFullPath(Path.Combine(app.Environment.ContentRootPath, "..", "..", "..", "Reading_v07.docx")),
                "/home/dazvo/Projects/www/KiemTraGiuaKy/Reading_v07.docx"
            };

            foreach (var docxPath in candidates)
            {
                if (File.Exists(docxPath))
                {
                    using var stream = File.OpenRead(docxPath);
                    var result = await parser.ParseAndSaveDocxAsync(stream, "TOEIC Reading Actual Test 01", requireAnswers: false);
                    if (result.IsSuccess)
                    {
                        Console.WriteLine($"--> [AutoSeed] Thành công nạp {result.TotalQuestionsParsed} câu hỏi từ '{docxPath}' vào 7 bảng CSDL!");
                        break;
                    }
                    else
                    {
                        Console.WriteLine($"--> [AutoSeed] Lỗi khi nạp: {string.Join(", ", result.Errors)}");
                    }
                }
            }
        }
    }
    catch (Exception ex)
    {
        Console.WriteLine($"--> [AutoSeed Error]: {ex.Message}");
    }
}

// Configure HTTP pipeline
if (app.Environment.IsDevelopment())
{
    app.UseDeveloperExceptionPage();
}
else
{
    app.UseExceptionHandler("/Home/Error");
}

app.UseStaticFiles();
app.UseRouting();
app.UseCors("DefaultCorsPolicy");

app.MapControllers();
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Exam}/{action=Index}/{id?}");

app.Run();
