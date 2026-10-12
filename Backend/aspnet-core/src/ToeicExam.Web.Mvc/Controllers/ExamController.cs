using System;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using ToeicExam.Exams;
using ToeicExam.Exams.Dto;

namespace ToeicExam.Web.Controllers;

[AllowAnonymous]
public class ExamController : Controller
{
    private readonly IToeicExamAppService _examAppService;
    private readonly IToeicDocxParserService _docxParserService;

    public ExamController(
        IToeicExamAppService examAppService,
        IToeicDocxParserService docxParserService)
    {
        _examAppService = examAppService;
        _docxParserService = docxParserService;
    }

    public async Task<IActionResult> Index()
    {
        var exams = await _examAppService.GetAllExamsAsync();
        return View(exams);
    }

    [HttpGet]
    public IActionResult Upload()
    {
        return View();
    }

    [HttpPost]
    [IgnoreAntiforgeryToken]
    public async Task<IActionResult> Upload(IFormFile? file, string? title, int durationMinutes = 75, bool requireAnswers = false)
    {
        if (file == null || file.Length == 0)
        {
            ViewBag.ErrorMessage = "Vui lòng chọn một file Word (.docx) để tải lên.";
            return View();
        }

        if (!file.FileName.EndsWith(".docx", StringComparison.OrdinalIgnoreCase))
        {
            ViewBag.ErrorMessage = "Định dạng file không hợp lệ. Vui lòng chọn file định dạng .docx.";
            return View();
        }

        using var memoryStream = new MemoryStream();
        await file.CopyToAsync(memoryStream);
        memoryStream.Position = 0;

        var parseResult = await _docxParserService.ParseAndSaveDocxAsync(
            memoryStream,
            string.IsNullOrWhiteSpace(title) ? file.FileName : title,
            requireAnswers: requireAnswers
        );

        if (!parseResult.IsSuccess)
        {
            ViewBag.ErrorMessage = "Quá trình đọc file Word phát hiện lỗi cấu trúc XML / Tag:";
            ViewBag.Errors = parseResult.Errors;
            ViewBag.Warnings = parseResult.Warnings;
            return View();
        }

        ViewBag.SuccessMessage = $"Nhập đề thi thành công! Đã lưu {parseResult.TotalQuestionsParsed} câu hỏi thuộc {parseResult.TotalPartsParsed} phần.";
        if (parseResult.Warnings.Count > 0)
        {
            ViewBag.Warnings = parseResult.Warnings;
        }

        if (parseResult.CreatedTest != null && parseResult.CreatedTest.Id > 0)
        {
            return RedirectToAction(nameof(Preview), new { id = parseResult.CreatedTest.Id });
        }

        return RedirectToAction(nameof(Index));
    }

    [HttpPost]
    [IgnoreAntiforgeryToken]
    public async Task<IActionResult> ValidateDocx(IFormFile? file, bool requireAnswers = false)
    {
        if (file == null || file.Length == 0)
        {
            return Json(new { isSuccess = false, errors = new[] { "Chưa chọn file." } });
        }

        using var memoryStream = new MemoryStream();
        await file.CopyToAsync(memoryStream);
        memoryStream.Position = 0;

        var validationResult = _docxParserService.ValidateDocxStream(memoryStream, requireAnswers);
        return Json(new
        {
            isSuccess = validationResult.IsSuccess,
            totalQuestions = validationResult.TotalQuestionsParsed,
            totalParts = validationResult.TotalPartsParsed,
            errors = validationResult.Errors,
            warnings = validationResult.Warnings
        });
    }

    [HttpGet]
    public async Task<IActionResult> Preview(int id)
    {
        if (id <= 0)
        {
            return RedirectToAction(nameof(Index));
        }

        try
        {
            var exam = await _examAppService.GetExamForAdminAsync(id);
            return View(exam);
        }
        catch (KeyNotFoundException)
        {
            return RedirectToAction(nameof(Index));
        }
    }

    [HttpPost]
    [IgnoreAntiforgeryToken]
    public async Task<IActionResult> EditQuestion([FromBody] EditQuestionInput input)
    {
        if (input == null || input.QuestionId <= 0)
        {
            return BadRequest(new { message = "Dữ liệu không hợp lệ." });
        }

        try
        {
            await _examAppService.UpdateQuestionAsync(input);
            return Json(new { success = true, message = "Cập nhật câu hỏi thành công!" });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { success = false, message = ex.Message });
        }
    }

    [HttpPost]
    public async Task<IActionResult> Delete(int id)
    {
        try
        {
            await _examAppService.DeleteExamAsync(id);
            return RedirectToAction(nameof(Index));
        }
        catch (Exception ex)
        {
            TempData["ErrorMessage"] = ex.Message;
            return RedirectToAction(nameof(Index));
        }
    }
}
