using System.IO;
using System.Threading.Tasks;
using Shouldly;
using ToeicExam.Exams;
using Xunit;

namespace ToeicExam.Tests.Exams;

public class DocxParser_Tests : ToeicExamTestBase
{
    private readonly IToeicDocxParserService _docxParser;
    private readonly IToeicExamAppService _examAppService;

    public DocxParser_Tests()
    {
        _docxParser = Resolve<IToeicDocxParserService>();
        _examAppService = Resolve<IToeicExamAppService>();
    }

    [Fact]
    public async Task Should_Parse_Reading_v07_Docx()
    {
        string filePath = "/home/dazvo/Projects/www/KiemTraGiuaKy/Reading_v07.docx";
        if (!File.Exists(filePath)) return;

        using var fs = File.OpenRead(filePath);
        var result = await _docxParser.ParseAndSaveDocxAsync(fs, "Test 07 Reading Actual", requireAnswers: false);

        result.IsSuccess.ShouldBeTrue();
        result.TotalQuestionsParsed.ShouldBeGreaterThan(50);
        result.TotalPartsParsed.ShouldBeGreaterThan(0);

        var exams = await _examAppService.GetAllExamsAsync();
        exams.ShouldNotBeEmpty();
    }
}
