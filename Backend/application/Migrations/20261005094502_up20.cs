using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace application.Migrations
{
    /// <inheritdoc />
    public partial class up20 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ProTaskCompletePaymentInfos_BookingInfos_BookId",
                table: "ProTaskCompletePaymentInfos");

            migrationBuilder.DropIndex(
                name: "IX_ProTaskCompletePaymentInfos_BookId",
                table: "ProTaskCompletePaymentInfos");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateIndex(
                name: "IX_ProTaskCompletePaymentInfos_BookId",
                table: "ProTaskCompletePaymentInfos",
                column: "BookId");

            migrationBuilder.AddForeignKey(
                name: "FK_ProTaskCompletePaymentInfos_BookingInfos_BookId",
                table: "ProTaskCompletePaymentInfos",
                column: "BookId",
                principalTable: "BookingInfos",
                principalColumn: "BookId",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
