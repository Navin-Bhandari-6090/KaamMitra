using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace application.Migrations
{
    /// <inheritdoc />
    public partial class addusernumbercolumninbookinginfotable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "UserNumber",
                table: "BookingInfos",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateIndex(
                name: "IX_BookingInfos_UserNumber",
                table: "BookingInfos",
                column: "UserNumber");

            migrationBuilder.AddForeignKey(
                name: "FK_BookingInfos_UserInfos_UserNumber",
                table: "BookingInfos",
                column: "UserNumber",
                principalTable: "UserInfos",
                principalColumn: "UserNumber",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_BookingInfos_UserInfos_UserNumber",
                table: "BookingInfos");

            migrationBuilder.DropIndex(
                name: "IX_BookingInfos_UserNumber",
                table: "BookingInfos");

            migrationBuilder.DropColumn(
                name: "UserNumber",
                table: "BookingInfos");
        }
    }
}
