using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace application.Migrations
{
    /// <inheritdoc />
    public partial class up27 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "BookingFile",
                table: "BookingInfos",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "BookingVideo",
                table: "BookingInfos",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "BookingFile",
                table: "BookingInfos");

            migrationBuilder.DropColumn(
                name: "BookingVideo",
                table: "BookingInfos");
        }
    }
}
