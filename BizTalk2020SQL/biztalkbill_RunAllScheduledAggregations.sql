CREATE PROCEDURE [dbo].[biztalkbill_RunAllScheduledAggregations]
AS
	declare @package nvarchar(250), @packageDTSX nvarchar(250)
	DECLARE BAMPackage_Cursor insensitive cursor for
	SELECT 'BAM_AN_' + [CubeName] as Package, 'BAM_AN_' + [CubeName] + '.dtsx' as PackageDTSX
    FROM [dbo].[bam_Metadata_AnalysisTasks]
	open BAMPackage_Cursor 
	
	fetch next from BAMPackage_Cursor into @package, @packageDTSX
	
	while @@fetch_status = 0
	 begin
		DECLARE @exec_id BIGINT

		EXEC [SSISDB].[catalog].[create_execution]
			@package_name=@packageDTSX,     --SSIS package name TABLE:(SELECT * FROM [SSISDB].internal.packages)
			@folder_name=N'BizTalk Server', --Folder were the package lives TABLE:(SELECT * FROM [SSISDB].internal.folders)
			@project_name=@package,--Project name were SSIS package lives TABLE:(SELECT * FROM [SSISDB].internal.projects)
			@use32bitruntime=FALSE,
			@reference_id=NULL,             --Environment reference, if null then no environment configuration is applied.
			@execution_id=@exec_id OUTPUT   --The paramter is outputed and contains the execution_id of your SSIS execution context.

		SELECT @exec_id

		EXEC [SSISDB].[catalog].[start_execution] @exec_id

		SELECT [STATUS]
			FROM [SSISDB].[internal].[operations]
			WHERE operation_id = @exec_id

		WHILE (SELECT [STATUS]
			FROM [SSISDB].[internal].[operations]
			WHERE operation_id = @exec_id) < 2
		begin
			WAITFOR DELAY '00:00:10' 
		end

		SELECT [STATUS]
			FROM [SSISDB].[internal].[operations]
			WHERE operation_id = @exec_id
		
		fetch next from BAMPackage_Cursor into @package, @packageDTSX
	 end
	
	close BAMPackage_Cursor 
	deallocate BAMPackage_Cursor 
RETURN 0

