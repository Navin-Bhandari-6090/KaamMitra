using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace application.Migrations
{
    /// <inheritdoc />
    public partial class up5 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "RatingGiver",
                table: "RatingInfos");

            migrationBuilder.DropColumn(
                name: "RatingReceiver",
                table: "RatingInfos");

            migrationBuilder.DropColumn(
                name: "ProviderEmail",
                table: "BookingInfos");

            migrationBuilder.DropColumn(
                name: "ServiceName",
                table: "BookingInfos");

            migrationBuilder.DropColumn(
                name: "UserEmail",
                table: "BookingInfos");

            migrationBuilder.AddColumn<int>(
                name: "RatingGiverNumber",
                table: "RatingInfos",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "RatingReceiverNumber",
                table: "RatingInfos",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "ProviderNumber",
                table: "BookingInfos",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.AddColumn<int>(
                name: "ServiceId",
                table: "BookingInfos",
                type: "integer",
                nullable: false,
                defaultValue: 0);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "RatingGiverNumber",
                table: "RatingInfos");

            migrationBuilder.DropColumn(
                name: "RatingReceiverNumber",
                table: "RatingInfos");

            migrationBuilder.DropColumn(
                name: "ProviderNumber",
                table: "BookingInfos");

            migrationBuilder.DropColumn(
                name: "ServiceId",
                table: "BookingInfos");

            migrationBuilder.AddColumn<string>(
                name: "RatingGiver",
                table: "RatingInfos",
                type: "character varying(200)",
                maxLength: 200,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "RatingReceiver",
                table: "RatingInfos",
                type: "character varying(200)",
                maxLength: 200,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "ProviderEmail",
                table: "BookingInfos",
                type: "character varying(200)",
                maxLength: 200,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "ServiceName",
                table: "BookingInfos",
                type: "character varying(200)",
                maxLength: 200,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "UserEmail",
                table: "BookingInfos",
                type: "character varying(200)",
                maxLength: 200,
                nullable: false,
                defaultValue: "");
        }
    }
}
