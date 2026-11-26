using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace application.Migrations
{
    /// <inheritdoc />
    public partial class AddChatMessageStatus : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "IsRead",
                table: "ChatInfos");

            migrationBuilder.AddColumn<DateTime>(
                name: "DeliveredAt",
                table: "ChatInfos",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "Status",
                table: "ChatInfos",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateIndex(
                name: "IX_ChatInfos_ReceiverNumber_Status",
                table: "ChatInfos",
                columns: new[] { "ReceiverNumber", "Status" });

            migrationBuilder.CreateIndex(
                name: "IX_ChatInfos_SenderNumber_ReceiverNumber_StoreAt",
                table: "ChatInfos",
                columns: new[] { "SenderNumber", "ReceiverNumber", "StoreAt" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_ChatInfos_ReceiverNumber_Status",
                table: "ChatInfos");

            migrationBuilder.DropIndex(
                name: "IX_ChatInfos_SenderNumber_ReceiverNumber_StoreAt",
                table: "ChatInfos");

            migrationBuilder.DropColumn(
                name: "DeliveredAt",
                table: "ChatInfos");

            migrationBuilder.DropColumn(
                name: "Status",
                table: "ChatInfos");

            migrationBuilder.AddColumn<bool>(
                name: "IsRead",
                table: "ChatInfos",
                type: "boolean",
                nullable: false,
                defaultValue: false);
        }
    }
}
