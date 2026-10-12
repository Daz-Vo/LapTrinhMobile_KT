using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using ToeicExam.Exams;
using ToeicExam.Exams.Dto;

namespace ToeicExam.Web.Controllers;

[ApiController]
[Route("api/exams")]
[AllowAnonymous]
public class ToeicExamApiController : ControllerBase
{
    private readonly IToeicExamAppService _examAppService;
    private readonly ToeicExam.EntityFrameworkCore.ToeicExamDbContext _db;

    public ToeicExamApiController(
        IToeicExamAppService examAppService,
        ToeicExam.EntityFrameworkCore.ToeicExamDbContext db)
    {
        _examAppService = examAppService;
        _db = db;
    }

    /// <summary>
    /// Lấy danh sách tất cả các bài thi TOEIC từ CSDL
    /// </summary>
    [HttpGet]
    public async Task<ActionResult<List<ExamListDto>>> GetAll()
    {
        var exams = await _examAppService.GetAllExamsAsync();
        return Ok(exams);
    }

    /// <summary>
    /// Lấy kết quả bài thi gần nhất
    /// </summary>
    [HttpGet("latest-attempt")]
    public async Task<ActionResult<ExamResultDto>> GetLatestAttempt([FromQuery] string? studentCode)
    {
        var attempt = await _examAppService.GetLatestAttemptAsync(studentCode);
        if (attempt == null)
        {
            return NotFound(new { message = "Chưa có lượt làm bài nào trong hệ thống." });
        }
        return Ok(attempt);
    }

    /// <summary>
    /// Lấy chi tiết bài thi để học sinh làm bài (ẩn đáp án đúng)
    /// </summary>
    [HttpGet("{id}")]
    public async Task<ActionResult<ExamDetailDto>> GetById(int id)
    {
        try
        {
            var exam = await _examAppService.GetExamForStudentAsync(id);
            return Ok(exam);
        }
        catch (KeyNotFoundException knf)
        {
            return NotFound(new { message = knf.Message });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = ex.Message });
        }
    }

    /// <summary>
    /// Nộp bài thi của thí sinh và tự động chấm điểm
    /// </summary>
    [HttpPost("{id}/submit")]
    public async Task<ActionResult<ExamResultDto>> Submit(int id, [FromBody] SubmitExamInput input)
    {
        if (input == null)
        {
            return BadRequest(new { message = "Dữ liệu nộp bài không hợp lệ." });
        }

        input.ExamId = id;
        try
        {
            var result = await _examAppService.SubmitExamAsync(input);
            return Ok(result);
        }
        catch (KeyNotFoundException knf)
        {
            return NotFound(new { message = knf.Message });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = ex.Message });
        }
    }
}
