using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace application.Migrations
{
    /// <inheritdoc />
    public partial class updatecolumnsdatatypeofTables : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "ServiceVideo",
                table: "ProviderServiceResourcesInfo",
                type: "text",
                nullable: false,
                oldClrType: typeof(byte[]),
                oldType: "bytea");

            migrationBuilder.AlterColumn<string>(
                name: "ServicePhoto",
                table: "ProviderServiceResourcesInfo",
                type: "text",
                nullable: false,
                oldClrType: typeof(byte[]),
                oldType: "bytea");

            migrationBuilder.AlterColumn<string>(
                name: "ServiceDocument",
                table: "ProviderServiceInfo",
                type: "text",
                nullable: false,
                oldClrType: typeof(byte[]),
                oldType: "bytea");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<byte[]>(
                name: "ServiceVideo",
                table: "ProviderServiceResourcesInfo",
                type: "bytea",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.AlterColumn<byte[]>(
                name: "ServicePhoto",
                table: "ProviderServiceResourcesInfo",
                type: "bytea",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "text");

            migrationBuilder.AlterColumn<byte[]>(
                name: "ServiceDocument",
                table: "ProviderServiceInfo",
                type: "bytea",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "text");
        }
    }
}
