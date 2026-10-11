using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace application.Migrations
{
    /// <inheritdoc />
    public partial class up22 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_AdvancePaymentInfos_BookingInfos_BookId",
                table: "AdvancePaymentInfos");

            migrationBuilder.DropForeignKey(
                name: "FK_RatingInfos_BookingInfos_BookId",
                table: "RatingInfos");

            migrationBuilder.DropIndex(
                name: "IX_RatingInfos_BookId",
                table: "RatingInfos");

            migrationBuilder.DropIndex(
                name: "IX_AdvancePaymentInfos_BookId",
                table: "AdvancePaymentInfos");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateIndex(
                name: "IX_RatingInfos_BookId",
                table: "RatingInfos",
                column: "BookId");

            migrationBuilder.CreateIndex(
                name: "IX_AdvancePaymentInfos_BookId",
                table: "AdvancePaymentInfos",
                column: "BookId");

            migrationBuilder.AddForeignKey(
                name: "FK_AdvancePaymentInfos_BookingInfos_BookId",
                table: "AdvancePaymentInfos",
                column: "BookId",
                principalTable: "BookingInfos",
                principalColumn: "BookId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_RatingInfos_BookingInfos_BookId",
                table: "RatingInfos",
                column: "BookId",
                principalTable: "BookingInfos",
                principalColumn: "BookId",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
