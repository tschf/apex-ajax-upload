set define off
set verify off
set feedback off
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK
begin wwv_flow.g_import_in_progress := true; end;
/
 
--       AAAA       PPPPP   EEEEEE  XX      XX
--      AA  AA      PP  PP  EE       XX    XX
--     AA    AA     PP  PP  EE        XX  XX
--    AAAAAAAAAA    PPPPP   EEEE       XXXX
--   AA        AA   PP      EE        XX  XX
--  AA          AA  PP      EE       XX    XX
--  AA          AA  PP      EEEEEE  XX      XX
prompt  Set Credentials...
 
begin
 
  -- Assumes you are running the script connected to SQL*Plus as the Oracle user APEX_040200 or as the owner (parsing schema) of the application.
  wwv_flow_api.set_security_group_id(p_security_group_id=>nvl(wwv_flow_application_install.get_workspace_id,245369616385306049));
 
end;
/

begin wwv_flow.g_import_in_progress := true; end;
/
begin 

select value into wwv_flow_api.g_nls_numeric_chars from nls_session_parameters where parameter='NLS_NUMERIC_CHARACTERS';

end;

/
begin execute immediate 'alter session set nls_numeric_characters=''.,''';

end;

/
begin wwv_flow.g_browser_language := 'en'; end;
/
prompt  Check Compatibility...
 
begin
 
-- This date identifies the minimum version required to import this file.
wwv_flow_api.set_version(p_version_yyyy_mm_dd=>'2012.01.01');
 
end;
/

prompt  Set Application ID...
 
begin
 
   -- SET APPLICATION ID
   wwv_flow.g_flow_id := nvl(wwv_flow_application_install.get_application_id,45448);
   wwv_flow_api.g_id_offset := nvl(wwv_flow_application_install.get_offset,0);
null;
 
end;
/

prompt  ...ui types
--
 
begin
 
null;
 
end;
/

prompt  ...plugins
--
--application/shared_components/plugins/item_type/ts_ajaxfileupload
 
begin
 
wwv_flow_api.create_plugin (
  p_id => 4090761942819551 + wwv_flow_api.g_id_offset
 ,p_flow_id => wwv_flow.g_flow_id
 ,p_plugin_type => 'ITEM TYPE'
 ,p_name => 'COM.GITHUB.TRENT-.APEX-AJAX-UPLOAD'
 ,p_display_name => 'AJAX File Upload'
 ,p_supported_ui_types => 'DESKTOP'
 ,p_image_prefix => '#PLUGIN_PREFIX#'
 ,p_plsql_code => 
'function get_region_id(p_region_name in varchar2) return varchar2'||unistr('\000a')||
'AS'||unistr('\000a')||
'	l_region_id varchar2(200);'||unistr('\000a')||
'BEGIN'||unistr('\000a')||
''||unistr('\000a')||
'	select ''#R''||region_id into l_region_id'||unistr('\000a')||
'	from apex_application_page_regions'||unistr('\000a')||
'	where page_id = ''&APP_PAGE_ID.'' and'||unistr('\000a')||
'	application_id = ''&APP_ID.'' and'||unistr('\000a')||
'	upper(region_name) = upper(p_region_name);'||unistr('\000a')||
'	'||unistr('\000a')||
'	return l_region_id;'||unistr('\000a')||
'	'||unistr('\000a')||
'	EXCEPTION'||unistr('\000a')||
'		WHEN'||unistr('\000a')||
'			NO_DATA_FOUND'||unistr('\000a')||
'				THEN'||unistr('\000a')||
'					RETURN NULL;--if the region isn'||
'ot found, simply no region will be refreshed'||unistr('\000a')||
''||unistr('\000a')||
'END get_region_id;'||unistr('\000a')||
''||unistr('\000a')||
'function base64_to_blob(p_base64 in clob) return BLOB'||unistr('\000a')||
'AS'||unistr('\000a')||
'	l_blob BLOB;'||unistr('\000a')||
'BEGIN'||unistr('\000a')||
''||unistr('\000a')||
'	l_blob := apex_web_service.clobbase642blob(p_base64);'||unistr('\000a')||
'	'||unistr('\000a')||
'	'||unistr('\000a')||
'	return l_blob;'||unistr('\000a')||
''||unistr('\000a')||
'END;'||unistr('\000a')||
''||unistr('\000a')||
'function get_base64 return clob'||unistr('\000a')||
'as'||unistr('\000a')||
'	l_clob CLOB;'||unistr('\000a')||
'	c_collection_name constant varchar2(200) := ''CLOB_CONTENT'';'||unistr('\000a')||
'begin'||unistr('\000a')||
''||unistr('\000a')||
'	select substr(clob001, instr(clob001, '','')+1, length(clo'||
'b001)) into l_clob'||unistr('\000a')||
'	from apex_collections'||unistr('\000a')||
'	where collection_name = c_collection_name;'||unistr('\000a')||
'	'||unistr('\000a')||
'	return l_clob;'||unistr('\000a')||
''||unistr('\000a')||
'end;'||unistr('\000a')||
''||unistr('\000a')||
''||unistr('\000a')||
'function render_file_item('||unistr('\000a')||
'	p_item                in apex_plugin.t_page_item,'||unistr('\000a')||
'	p_plugin              in apex_plugin.t_plugin,'||unistr('\000a')||
'	p_value               in varchar2,'||unistr('\000a')||
'	p_is_readonly         in boolean,'||unistr('\000a')||
'	p_is_printer_friendly in boolean )'||unistr('\000a')||
'return apex_plugin.t_page_item_render_result'||unistr('\000a')||
'AS'||unistr('\000a')||
'	l_resu'||
'lt apex_plugin.t_page_item_render_result;'||unistr('\000a')||
'	l_ajax_ident varchar2(255) := apex_plugin.get_ajax_identifier;'||unistr('\000a')||
'	l_report_region_id varchar2(200) := get_region_id(p_item.attribute_08);'||unistr('\000a')||
'BEGIN'||unistr('\000a')||
'	if apex_application.g_debug then'||unistr('\000a')||
'		apex_plugin_util.debug_page_item ('||unistr('\000a')||
'			p_plugin              => p_plugin,'||unistr('\000a')||
'			p_page_item           => p_item,'||unistr('\000a')||
'			p_value               => p_value,'||unistr('\000a')||
'			p_is_readonly         => p_is_'||
'readonly,'||unistr('\000a')||
'			p_is_printer_friendly => p_is_printer_friendly );'||unistr('\000a')||
'	end if;'||unistr('\000a')||
''||unistr('\000a')||
''||unistr('\000a')||
'	apex_javascript.add_inline_code('||unistr('\000a')||
'		p_code => '''||unistr('\000a')||
'	'||unistr('\000a')||
'			var fileList;'||unistr('\000a')||
'			var currFule;'||unistr('\000a')||
'			var gIndex;'||unistr('\000a')||
'			'||unistr('\000a')||
'			function uploadFiles(fileList){'||unistr('\000a')||
'				'||unistr('\000a')||
'				'||unistr('\000a')||
'				//step 1. check if file list was passed in. if it was, set the global variable				'||unistr('\000a')||
'				if(fileList != null){'||unistr('\000a')||
'					$x_Show(''''AjaxLoading'''');'||unistr('\000a')||
'					this.fileList = fileList;'||unistr('\000a')||
'			'||
'		gIndex = 0;'||unistr('\000a')||
'				}'||unistr('\000a')||
'				'||unistr('\000a')||
'				//no more files to read'||unistr('\000a')||
'				if (gIndex >= this.fileList.length){'||unistr('\000a')||
'					$x_Hide(''''AjaxLoading'''');'||unistr('\000a')||
'					$(''''#'' || p_item.name || '''''').val('''''''');'||unistr('\000a')||
'					return;'||unistr('\000a')||
'				}'||unistr('\000a')||
'				//step 2. check the global gile list exists. if it does get the the current file'||unistr('\000a')||
'				if (this.fileList != null){'||unistr('\000a')||
'					currFile = this.fileList[gIndex++];//get the first file'||unistr('\000a')||
'					'||unistr('\000a')||
'					'||unistr('\000a')||
'					var fileReader '||
'= new FileReader();//create the file reader object'||unistr('\000a')||
'					fileReader.onload = addToCollection;//declare the callback function'||unistr('\000a')||
'					fileReader.readAsDataURL(currFile);//read the file data'||unistr('\000a')||
'				}'||unistr('\000a')||
'				'||unistr('\000a')||
'			}'||unistr('\000a')||
'			'||unistr('\000a')||
'			function addToCollection(e){'||unistr('\000a')||
'				'||unistr('\000a')||
'				var base64 = e.target.result;'||unistr('\000a')||
'				var clob_ob = new apex.ajax.clob('||unistr('\000a')||
'					function(){'||unistr('\000a')||
'						var rs = p.readyState;'||unistr('\000a')||
''||unistr('\000a')||
'						if (rs == 4){'||unistr('\000a')||
'							addToDB();'||unistr('\000a')||
'	'||
'					} '||unistr('\000a')||
'					}'||unistr('\000a')||
'				);'||unistr('\000a')||
'					'||unistr('\000a')||
'				clob_ob._set(base64);'||unistr('\000a')||
'				'||unistr('\000a')||
'			}'||unistr('\000a')||
'			'||unistr('\000a')||
'			'||unistr('\000a')||
'			function addToDB(){'||unistr('\000a')||
'				'||unistr('\000a')||
'				$.post('||unistr('\000a')||
'					''''wwv_flow.show'''',  '||unistr('\000a')||
'					{'' || '||unistr('\000a')||
'						apex_javascript.add_attribute(''p_request'',''PLUGIN='' || l_ajax_ident) || '||unistr('\000a')||
'						apex_javascript.add_attribute(''p_flow_id'', ''&APP_ID.'') ||'||unistr('\000a')||
'						apex_javascript.add_attribute(''p_flow_step_id'', ''&APP_PAGE_ID.'') ||'||unistr('\000a')||
'						apex_javascript.add_attribu'||
'te(''p_instance'', ''&APP_SESSION.'',true,true) ||'||unistr('\000a')||
'						''"x01" : currFile.name,'||unistr('\000a')||
'						 "x02" : currFile.type'||unistr('\000a')||
'					},'||unistr('\000a')||
'					function success(){ '||unistr('\000a')||
'						$('''''' || l_report_region_id || '''''').trigger(''''apexrefresh'''');//refresh region'||unistr('\000a')||
'						uploadFiles();//do the next file'||unistr('\000a')||
'					'||unistr('\000a')||
'					});'||unistr('\000a')||
'				'||unistr('\000a')||
'			}'||unistr('\000a')||
'		'||unistr('\000a')||
'	'||unistr('\000a')||
'	'');'||unistr('\000a')||
''||unistr('\000a')||
'	'||unistr('\000a')||
''||unistr('\000a')||
'	sys.htp.p(''<div id="AjaxLoading" style="display:none;position:absolute;left:45%;top:45%;padding:1'||
'0px;border:2px solid black;background:#FFF;" > Uploading..... <br /><img src="#IMAGE_PREFIX#processing3.gif" /></div>'');'||unistr('\000a')||
'	sys.htp.p(''<input type="file" id="'' || p_item.name || ''" value="'' || p_value || ''" multiple />'');'||unistr('\000a')||
'	sys.htp.p('''||unistr('\000a')||
''||unistr('\000a')||
'		<button value="Submit" onclick="uploadFiles($x('' || p_item.name || '').files);" class="button-gray" type="button">'||unistr('\000a')||
'			<span>Submit</span>'||unistr('\000a')||
'		</button>'||unistr('\000a')||
''||unistr('\000a')||
'	'');'||unistr('\000a')||
''||unistr('\000a')||
'	return '||
'l_result;'||unistr('\000a')||
'END render_file_item;'||unistr('\000a')||
''||unistr('\000a')||
''||unistr('\000a')||
'function add_file ('||unistr('\000a')||
'	p_item   in apex_plugin.t_page_item,'||unistr('\000a')||
'	p_plugin in apex_plugin.t_plugin )'||unistr('\000a')||
'return apex_plugin.t_page_item_ajax_result'||unistr('\000a')||
'AS'||unistr('\000a')||
'	'||unistr('\000a')||
''||unistr('\000a')||
'	'||unistr('\000a')||
'	l_result apex_plugin.t_page_item_ajax_result;'||unistr('\000a')||
'	'||unistr('\000a')||
'	'||unistr('\000a')||
'	'||unistr('\000a')||
'	l_table_name p_item.attribute_01%type := p_item.attribute_01;'||unistr('\000a')||
'	l_filename p_item.attribute_02%type := p_item.attribute_02;'||unistr('\000a')||
'	l_mime_type p_item.attribute_03%type := p_i'||
'tem.attribute_03;'||unistr('\000a')||
'	l_blob_column p_item.attribute_04%type := p_item.attribute_04;'||unistr('\000a')||
'	l_blob BLOB := base64_to_blob(get_base64);'||unistr('\000a')||
'	l_foreign_key_item p_item.attribute_06%type := p_item.attribute_06;'||unistr('\000a')||
'	l_foreign_key_column p_item.attribute_07%type := p_item.attribute_07;'||unistr('\000a')||
''||unistr('\000a')||
'	'||unistr('\000a')||
'	c_foreign_key_col constant varchar2(200) := ''#FOREIGN_KEY_COL#'';'||unistr('\000a')||
'	c_foreign_key_col_replace constant varchar2(200) := '','' || l_for'||
'eign_key_column;'||unistr('\000a')||
'	'||unistr('\000a')||
'	c_foreign_key_val constant varchar2(200) := ''#FOREIGN_KEY_VAL#'';'||unistr('\000a')||
'	c_foreign_key_val_replace constant varchar2(200) := '',:4'';'||unistr('\000a')||
'	'||unistr('\000a')||
'	l_insert_stmt varchar2(4000) := ''insert into '' ||  l_table_name || '' ('' || l_filename || '','' || l_mime_type || '','' || l_blob_column || c_foreign_key_col || '') values (:1, :2, :3'' || c_foreign_key_val || '')'';'||unistr('\000a')||
'	l_insert_stmt2 varchar2(4000) := ''insert in'||
'to '' ||  l_table_name || '' ('' || l_filename || '','' || l_mime_type || '','' || l_blob_column || '') values (:1, :2, :3)'';'||unistr('\000a')||
'BEGIN'||unistr('\000a')||
'	'||unistr('\000a')||
'	IF l_foreign_key_item IS NOT NULL THEN --replace substitutions with actual values'||unistr('\000a')||
'		l_insert_stmt := REPLACE(l_insert_stmt, c_foreign_key_col, c_foreign_key_col_replace);'||unistr('\000a')||
'		l_insert_stmt := REPLACE(l_insert_stmt, c_foreign_key_val, c_foreign_key_val_replace);'||unistr('\000a')||
'		execute imm'||
'ediate l_insert_stmt using apex_application.g_x01, apex_application.g_x02, l_blob, v(l_foreign_key_item);'||unistr('\000a')||
'	ELSE --replace with empty strings'||unistr('\000a')||
'		l_insert_stmt := REPLACE(l_insert_stmt, c_foreign_key_col, '''');'||unistr('\000a')||
'		l_insert_stmt := REPLACE(l_insert_stmt, c_foreign_key_val, '''');'||unistr('\000a')||
'		execute immediate l_insert_stmt using apex_application.g_x01, apex_application.g_x02, l_blob;'||unistr('\000a')||
'	END IF;'||unistr('\000a')||
'	return l_result;'||unistr('\000a')||
'END '||
'add_file;'
 ,p_render_function => 'render_file_item'
 ,p_ajax_function => 'add_file'
 ,p_standard_attributes => 'VISIBLE'
 ,p_substitute_attributes => true
 ,p_subscribe_plugin_settings => true
 ,p_help_text => '<p>'||unistr('\000a')||
'	Add AJAX File Upload to your page, specify attributes. Click submit to upload files</p>'||unistr('\000a')||
'<p>'||unistr('\000a')||
'	WIll NOT work on IE</p>'||unistr('\000a')||
''
 ,p_version_identifier => '1.0.0'
 ,p_plugin_comment => 'todo: return primary key into session item'
  );
wwv_flow_api.create_plugin_attribute (
  p_id => 4090934500830530 + wwv_flow_api.g_id_offset
 ,p_flow_id => wwv_flow.g_flow_id
 ,p_plugin_id => 4090761942819551 + wwv_flow_api.g_id_offset
 ,p_attribute_scope => 'COMPONENT'
 ,p_attribute_sequence => 1
 ,p_display_sequence => 10
 ,p_prompt => 'Table Name'
 ,p_attribute_type => 'TEXT'
 ,p_is_required => true
 ,p_is_translatable => false
 ,p_help_text => 'Specify the table name for which the selected files will be insert into.'
  );
wwv_flow_api.create_plugin_attribute (
  p_id => 4146647877274153 + wwv_flow_api.g_id_offset
 ,p_flow_id => wwv_flow.g_flow_id
 ,p_plugin_id => 4090761942819551 + wwv_flow_api.g_id_offset
 ,p_attribute_scope => 'COMPONENT'
 ,p_attribute_sequence => 2
 ,p_display_sequence => 20
 ,p_prompt => 'File Name Column'
 ,p_attribute_type => 'TEXT'
 ,p_is_required => true
 ,p_default_value => 'filename'
 ,p_is_translatable => false
 ,p_help_text => 'Specify the column name for the file name.'
  );
wwv_flow_api.create_plugin_attribute (
  p_id => 4157258424090331 + wwv_flow_api.g_id_offset
 ,p_flow_id => wwv_flow.g_flow_id
 ,p_plugin_id => 4090761942819551 + wwv_flow_api.g_id_offset
 ,p_attribute_scope => 'COMPONENT'
 ,p_attribute_sequence => 3
 ,p_display_sequence => 30
 ,p_prompt => 'Mime Type Column '
 ,p_attribute_type => 'TEXT'
 ,p_is_required => true
 ,p_default_value => 'mime_type'
 ,p_is_translatable => false
 ,p_help_text => 'Specify the column name for the mime type.'
  );
wwv_flow_api.create_plugin_attribute (
  p_id => 4157842278095114 + wwv_flow_api.g_id_offset
 ,p_flow_id => wwv_flow.g_flow_id
 ,p_plugin_id => 4090761942819551 + wwv_flow_api.g_id_offset
 ,p_attribute_scope => 'COMPONENT'
 ,p_attribute_sequence => 4
 ,p_display_sequence => 40
 ,p_prompt => 'Blob Column'
 ,p_attribute_type => 'TEXT'
 ,p_is_required => true
 ,p_is_translatable => false
 ,p_help_text => 'Specify the column name for the blob data.'
  );
wwv_flow_api.create_plugin_attribute (
  p_id => 4159039293103671 + wwv_flow_api.g_id_offset
 ,p_flow_id => wwv_flow.g_flow_id
 ,p_plugin_id => 4090761942819551 + wwv_flow_api.g_id_offset
 ,p_attribute_scope => 'COMPONENT'
 ,p_attribute_sequence => 6
 ,p_display_sequence => 60
 ,p_prompt => 'Item Containing Foreign Key'
 ,p_attribute_type => 'TEXT'
 ,p_is_required => false
 ,p_is_translatable => false
 ,p_depending_on_condition_type => 'EQUALS'
 ,p_depending_on_expression => 'Y'
 ,p_help_text => 'Page item containing foreign key'
  );
wwv_flow_api.create_plugin_attribute (
  p_id => 4166043596614993 + wwv_flow_api.g_id_offset
 ,p_flow_id => wwv_flow.g_flow_id
 ,p_plugin_id => 4090761942819551 + wwv_flow_api.g_id_offset
 ,p_attribute_scope => 'COMPONENT'
 ,p_attribute_sequence => 7
 ,p_display_sequence => 70
 ,p_prompt => 'Foreign Key Column'
 ,p_attribute_type => 'TEXT'
 ,p_is_required => false
 ,p_is_translatable => false
 ,p_help_text => 'Specify the column containing the foreign key'
  );
  
wwv_flow_api.create_plugin_attribute (
  p_id => 4167135762622215 + wwv_flow_api.g_id_offset
 ,p_flow_id => wwv_flow.g_flow_id
 ,p_plugin_id => 4090761942819551 + wwv_flow_api.g_id_offset
 ,p_attribute_scope => 'COMPONENT'
 ,p_attribute_sequence => 8
 ,p_display_sequence => 80
 ,p_prompt => 'Region To Refresh'
 ,p_attribute_type => 'TEXT'
 ,p_is_required => false
 ,p_is_translatable => false
 ,p_help_text => 'Specify the region name to refresh after inserting files. i.e. report of files. Region name should match exactly and must be unique for the current page.'
  );
wwv_flow_api.create_plugin_attribute (
  p_id => 10888971022410610407 + wwv_flow_api.g_id_offset
 ,p_flow_id => wwv_flow.g_flow_id
 ,p_plugin_id => 4090761942819551 + wwv_flow_api.g_id_offset
 ,p_attribute_scope => 'COMPONENT'
 ,p_attribute_sequence => 9
 ,p_display_sequence => 90
 ,p_prompt => 'yn1'
 ,p_attribute_type => 'CHECKBOX'
 ,p_is_required => false
 ,p_default_value => 'N'
 ,p_is_translatable => false
  );
wwv_flow_api.create_plugin_attribute (
  p_id => 10888972625873611384 + wwv_flow_api.g_id_offset
 ,p_flow_id => wwv_flow.g_flow_id
 ,p_plugin_id => 4090761942819551 + wwv_flow_api.g_id_offset
 ,p_attribute_scope => 'COMPONENT'
 ,p_attribute_sequence => 10
 ,p_display_sequence => 100
 ,p_prompt => 'yn2'
 ,p_attribute_type => 'CHECKBOX'
 ,p_is_required => false
 ,p_default_value => 'N'
 ,p_is_translatable => false
  );
null;
 
end;
/

commit;
begin
execute immediate 'begin sys.dbms_session.set_nls( param => ''NLS_NUMERIC_CHARACTERS'', value => '''''''' || replace(wwv_flow_api.g_nls_numeric_chars,'''''''','''''''''''') || ''''''''); end;';
end;
/
set verify on
set feedback on
set define on
prompt  ...done
