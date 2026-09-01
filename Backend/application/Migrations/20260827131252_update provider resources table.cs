using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace application.Migrations
{
    /// <inheritdoc />
    public partial class updateproviderresourcestable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ProviderServiceResources_ProviderServiceInfo_ProviderServic~",
                table: "ProviderServiceResources");

            migrationBuilder.DropForeignKey(
                name: "FK_ProviderServiceResources_UserInfos_Email",
                table: "ProviderServiceResources");

            migrationBuilder.DropPrimaryKey(
                name: "PK_ProviderServiceResources",
                table: "ProviderServiceResources");

            migrationBuilder.RenameTable(
                name: "ProviderServiceResources",
                newName: "ProviderServiceResourcesInfo");

            migrationBuilder.RenameIndex(
                name: "IX_ProviderServiceResources_ProviderServiceId",
                table: "ProviderServiceResourcesInfo",
                newName: "IX_ProviderServiceResourcesInfo_ProviderServiceId");

            migrationBuilder.RenameIndex(
                name: "IX_ProviderServiceResources_Email",
                table: "ProviderServiceResourcesInfo",
                newName: "IX_ProviderServiceResourcesInfo_Email");

            migrationBuilder.AddPrimaryKey(
                name: "PK_ProviderServiceResourcesInfo",
                table: "ProviderServiceResourcesInfo",
                column: "ProviderServiceResourcesId");

            migrationBuilder.AddForeignKey(
                name: "FK_ProviderServiceResourcesInfo_ProviderServiceInfo_ProviderSe~",
                table: "ProviderServiceResourcesInfo",
                column: "ProviderServiceId",
                principalTable: "ProviderServiceInfo",
                principalColumn: "ProviderServiceId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_ProviderServiceResourcesInfo_UserInfos_Email",
                table: "ProviderServiceResourcesInfo",
                column: "Email",
                principalTable: "UserInfos",
                principalColumn: "Email",
                onDelete: ReferentialAction.Cascade);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_ProviderServiceResourcesInfo_ProviderServiceInfo_ProviderSe~",
                table: "ProviderServiceResourcesInfo");

            migrationBuilder.DropForeignKey(
                name: "FK_ProviderServiceResourcesInfo_UserInfos_Email",
                table: "ProviderServiceResourcesInfo");

            migrationBuilder.DropPrimaryKey(
                name: "PK_ProviderServiceResourcesInfo",
                table: "ProviderServiceResourcesInfo");

            migrationBuilder.RenameTable(
                name: "ProviderServiceResourcesInfo",
                newName: "ProviderServiceResources");

            migrationBuilder.RenameIndex(
                name: "IX_ProviderServiceResourcesInfo_ProviderServiceId",
                table: "ProviderServiceResources",
                newName: "IX_ProviderServiceResources_ProviderServiceId");

            migrationBuilder.RenameIndex(
                name: "IX_ProviderServiceResourcesInfo_Email",
                table: "ProviderServiceResources",
                newName: "IX_ProviderServiceResources_Email");

            migrationBuilder.AddPrimaryKey(
                name: "PK_ProviderServiceResources",
                table: "ProviderServiceResources",
                column: "ProviderServiceResourcesId");

            migrationBuilder.AddForeignKey(
                name: "FK_ProviderServiceResources_ProviderServiceInfo_ProviderServic~",
                table: "ProviderServiceResources",
                column: "ProviderServiceId",
                principalTable: "ProviderServiceInfo",
                principalColumn: "ProviderServiceId",
                onDelete: ReferentialAction.Cascade);

            migrationBuilder.AddForeignKey(
                name: "FK_ProviderServiceResources_UserInfos_Email",
                table: "ProviderServiceResources",
                column: "Email",
                principalTable: "UserInfos",
                principalColumn: "Email",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
