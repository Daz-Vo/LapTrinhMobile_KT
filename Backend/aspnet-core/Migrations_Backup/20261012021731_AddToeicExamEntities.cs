using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace ToeicExam.Migrations
{
    /// <inheritdoc />
    public partial class AddToeicExamEntities : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "AppToeicTests",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    Title = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: false),
                    DurationMinutes = table.Column<int>(type: "int", nullable: false),
                    TotalQuestions = table.Column<int>(type: "int", nullable: false),
                    Description = table.Column<string>(type: "nvarchar(1000)", maxLength: 1000, nullable: true),
                    SourceFileName = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: true),
                    CreationTime = table.Column<DateTime>(type: "datetime2", nullable: false),
                    CreatorUserId = table.Column<long>(type: "bigint", nullable: true),
                    LastModificationTime = table.Column<DateTime>(type: "datetime2", nullable: true),
                    LastModifierUserId = table.Column<long>(type: "bigint", nullable: true),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false),
                    DeleterUserId = table.Column<long>(type: "bigint", nullable: true),
                    DeletionTime = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AppToeicTests", x => x.Id);
                });

            migrationBuilder.CreateTable(
                name: "AppToeicParts",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ToeicTestId = table.Column<int>(type: "int", nullable: false),
                    PartNumber = table.Column<int>(type: "int", nullable: false),
                    Name = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: false),
                    QuestionStart = table.Column<int>(type: "int", nullable: false),
                    QuestionEnd = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AppToeicParts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AppToeicParts_AppToeicTests_ToeicTestId",
                        column: x => x.ToeicTestId,
                        principalTable: "AppToeicTests",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AppUserExamAttempts",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ToeicTestId = table.Column<int>(type: "int", nullable: false),
                    StudentName = table.Column<string>(type: "nvarchar(128)", maxLength: 128, nullable: true),
                    StudentCode = table.Column<string>(type: "nvarchar(64)", maxLength: 64, nullable: true),
                    StartTime = table.Column<DateTime>(type: "datetime2", nullable: false),
                    SubmitTime = table.Column<DateTime>(type: "datetime2", nullable: true),
                    TotalCorrect = table.Column<int>(type: "int", nullable: false),
                    TotalWrong = table.Column<int>(type: "int", nullable: false),
                    TotalSkipped = table.Column<int>(type: "int", nullable: false),
                    EstimatedScore = table.Column<int>(type: "int", nullable: false),
                    CreationTime = table.Column<DateTime>(type: "datetime2", nullable: false),
                    CreatorUserId = table.Column<long>(type: "bigint", nullable: true),
                    LastModificationTime = table.Column<DateTime>(type: "datetime2", nullable: true),
                    LastModifierUserId = table.Column<long>(type: "bigint", nullable: true),
                    IsDeleted = table.Column<bool>(type: "bit", nullable: false),
                    DeleterUserId = table.Column<long>(type: "bigint", nullable: true),
                    DeletionTime = table.Column<DateTime>(type: "datetime2", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AppUserExamAttempts", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AppUserExamAttempts_AppToeicTests_ToeicTestId",
                        column: x => x.ToeicTestId,
                        principalTable: "AppToeicTests",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AppQuestionGroups",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    ToeicPartId = table.Column<int>(type: "int", nullable: false),
                    GroupCode = table.Column<string>(type: "nvarchar(64)", maxLength: 64, nullable: true),
                    GroupTitle = table.Column<string>(type: "nvarchar(256)", maxLength: 256, nullable: true),
                    PassageText = table.Column<string>(type: "nvarchar(max)", nullable: true),
                    ImageUrl = table.Column<string>(type: "nvarchar(512)", maxLength: 512, nullable: true),
                    OrderIndex = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AppQuestionGroups", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AppQuestionGroups_AppToeicParts_ToeicPartId",
                        column: x => x.ToeicPartId,
                        principalTable: "AppToeicParts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AppQuestions",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    QuestionGroupId = table.Column<int>(type: "int", nullable: false),
                    QuestionNumber = table.Column<int>(type: "int", nullable: false),
                    Content = table.Column<string>(type: "nvarchar(max)", nullable: false),
                    CorrectOption = table.Column<string>(type: "nvarchar(8)", maxLength: 8, nullable: true),
                    OrderIndex = table.Column<int>(type: "int", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AppQuestions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AppQuestions_AppQuestionGroups_QuestionGroupId",
                        column: x => x.QuestionGroupId,
                        principalTable: "AppQuestionGroups",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AppQuestionOptions",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    QuestionId = table.Column<int>(type: "int", nullable: false),
                    OptionLabel = table.Column<string>(type: "nvarchar(8)", maxLength: 8, nullable: false),
                    Content = table.Column<string>(type: "nvarchar(max)", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AppQuestionOptions", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AppQuestionOptions_AppQuestions_QuestionId",
                        column: x => x.QuestionId,
                        principalTable: "AppQuestions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "AppUserExamAnswers",
                columns: table => new
                {
                    Id = table.Column<int>(type: "int", nullable: false)
                        .Annotation("SqlServer:Identity", "1, 1"),
                    AttemptId = table.Column<int>(type: "int", nullable: false),
                    QuestionId = table.Column<int>(type: "int", nullable: false),
                    QuestionNumber = table.Column<int>(type: "int", nullable: false),
                    SelectedOption = table.Column<string>(type: "nvarchar(8)", maxLength: 8, nullable: true),
                    CorrectOption = table.Column<string>(type: "nvarchar(8)", maxLength: 8, nullable: true),
                    IsCorrect = table.Column<bool>(type: "bit", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_AppUserExamAnswers", x => x.Id);
                    table.ForeignKey(
                        name: "FK_AppUserExamAnswers_AppQuestions_QuestionId",
                        column: x => x.QuestionId,
                        principalTable: "AppQuestions",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_AppUserExamAnswers_AppUserExamAttempts_AttemptId",
                        column: x => x.AttemptId,
                        principalTable: "AppUserExamAttempts",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_AppQuestionGroups_ToeicPartId",
                table: "AppQuestionGroups",
                column: "ToeicPartId");

            migrationBuilder.CreateIndex(
                name: "IX_AppQuestionOptions_QuestionId",
                table: "AppQuestionOptions",
                column: "QuestionId");

            migrationBuilder.CreateIndex(
                name: "IX_AppQuestions_QuestionGroupId",
                table: "AppQuestions",
                column: "QuestionGroupId");

            migrationBuilder.CreateIndex(
                name: "IX_AppToeicParts_ToeicTestId",
                table: "AppToeicParts",
                column: "ToeicTestId");

            migrationBuilder.CreateIndex(
                name: "IX_AppUserExamAnswers_AttemptId",
                table: "AppUserExamAnswers",
                column: "AttemptId");

            migrationBuilder.CreateIndex(
                name: "IX_AppUserExamAnswers_QuestionId",
                table: "AppUserExamAnswers",
                column: "QuestionId");

            migrationBuilder.CreateIndex(
                name: "IX_AppUserExamAttempts_ToeicTestId",
                table: "AppUserExamAttempts",
                column: "ToeicTestId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "AppQuestionOptions");

            migrationBuilder.DropTable(
                name: "AppUserExamAnswers");

            migrationBuilder.DropTable(
                name: "AppQuestions");

            migrationBuilder.DropTable(
                name: "AppUserExamAttempts");

            migrationBuilder.DropTable(
                name: "AppQuestionGroups");

            migrationBuilder.DropTable(
                name: "AppToeicParts");

            migrationBuilder.DropTable(
                name: "AppToeicTests");
        }
    }
}
