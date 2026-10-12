using Microsoft.AspNetCore.Authorization;
using ToeicExam.Controllers;
using Microsoft.AspNetCore.Mvc;

namespace ToeicExam.Web.Controllers;

[AllowAnonymous]
public class AboutController : ToeicExamControllerBase
{
    public ActionResult Index()
    {
        return RedirectToAction("Index", "Exam");
    }
}
