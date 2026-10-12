using Abp.Application.Navigation;
using Abp.Authorization;
using Abp.Localization;
using ToeicExam.Authorization;

namespace ToeicExam.Web.Startup;

/// <summary>
/// This class defines menus for the application.
/// </summary>
public class ToeicExamNavigationProvider : NavigationProvider
{
    public override void SetNavigation(INavigationProviderContext context)
    {
        context.Manager.MainMenu
            .AddItem(
                new MenuItemDefinition(
                    "Exams",
                    new FixedLocalizableString("Quản lý Đề thi TOEIC"),
                    url: "Exam",
                    icon: "fas fa-file-alt"
                )
            )
            .AddItem(
                new MenuItemDefinition(
                    "UploadExam",
                    new FixedLocalizableString("Tải lên đề thi (.docx)"),
                    url: "Exam/Upload",
                    icon: "fas fa-cloud-upload-alt"
                )
            );
    }

    private static ILocalizableString L(string name)
    {
        return new LocalizableString(name, ToeicExamConsts.LocalizationSourceName);
    }
}