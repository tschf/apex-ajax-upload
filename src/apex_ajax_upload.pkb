create or replace PACKAGE BODY APEX_AJAX_UPLOAD AS

    function get_region_id(p_region_name in varchar2) return varchar2
    AS
        l_region_id varchar2(200);
    BEGIN

        select '#R'||region_id into l_region_id
        from apex_application_page_regions
        where page_id = apex_application.g_flow_step_id and
        application_id = apex_application.g_flow_id and
        upper(region_name) = upper(p_region_name);
        
        return l_region_id;
        
        EXCEPTION
            WHEN
                NO_DATA_FOUND
                    THEN
                        RETURN NULL;--if the region isnot found, simply no region will be refreshed
    
    END get_region_id;

    function base64_to_blob(p_base64 in clob) return BLOB
    AS
        l_blob BLOB;
    BEGIN
    
        l_blob := apex_web_service.clobbase642blob(p_base64);
        
        
        return l_blob;
    
    END;

    function get_base64 return clob
    as
        l_clob CLOB;
        c_collection_name constant varchar2(200) := 'CLOB_CONTENT';
    begin
    
        select substr(clob001, instr(clob001, ',')+1, length(clob001)) into l_clob
        from apex_collections
        where collection_name = c_collection_name;
        
        return l_clob;
    
    end;


    function render_file_item(
        p_item                in apex_plugin.t_page_item,
        p_plugin              in apex_plugin.t_plugin,
        p_value               in varchar2,
        p_is_readonly         in boolean,
        p_is_printer_friendly in boolean )
    return apex_plugin.t_page_item_render_result
    AS
        l_result apex_plugin.t_page_item_render_result;
        l_ajax_ident varchar2(255);
        l_report_region_id varchar2(200);
        
        l_js_code varchar2(4000);
    BEGIN
    
        l_ajax_ident := apex_plugin.get_ajax_identifier;
        l_report_region_id := get_region_id(p_item.attribute_08);
        
        if apex_application.g_debug then
            apex_plugin_util.debug_page_item (
                p_plugin              => p_plugin,
                p_page_item           => p_item,
                p_value               => p_value,
                p_is_readonly         => p_is_readonly,
                p_is_printer_friendly => p_is_printer_friendly );
        end if;
        
        l_js_code := q'!
        
        var fileList;
        var currFule;
        var gIndex;
        
        function uploadFiles(fileList){
            
            
            //step 1. check if file list was passed in. if it was, set the global variable				
            if(fileList != null){
                $x_Show('AjaxLoading');
                this.fileList = fileList;
                gIndex = 0;
            }
            
            //no more files to read
            if (gIndex >= this.fileList.length){
                $x_Hide('AjaxLoading');
                $('##item_name#').val('');
                return;
            }
            
            //step 2. check the global file list exists. if it does get the the current file
            if (this.fileList != null){
                currFile = this.fileList[gIndex++];//get the first file
                
                
                var fileReader = new FileReader();//create the file reader object
                fileReader.onload = addToCollection;//declare the callback function
                fileReader.readAsDataURL(currFile);//read the file data
            }
            
        }
        
        function addToCollection(e){
            
            var base64 = e.target.result;
            var clob_ob = new apex.ajax.clob(
                function(){
                    var rs = p.readyState;

                    if (rs == 4){
                        addToDB();
                    } 
                }
            );
                
            clob_ob._set(base64);
            
        }
        
        
        function addToDB(){
            
            $.post(
                'wwv_flow.show',  
                {
                    #p_request#
                    #p_flow_id#
                    #p_flow_step_id#
                    #p_instance#
                    #x01#
                    #x02#
                },
                function success(){ 
                    $('##report_region_id#').trigger('apexrefresh');
                    uploadFiles();//do the next file
                
                });
            
        }
        
        !';
        
        l_js_code := replace(l_js_code, '#item_name#', p_item.name);
        l_js_code := replace(l_js_code, '#report_region_id#', l_report_region_id);
        l_js_code := replace(l_js_code, '#p_request#', apex_javascript.add_attribute('p_request','PLUGIN=' || l_ajax_ident));
        l_js_code := replace(l_js_code, '#p_flow_id#', apex_javascript.add_attribute('p_flow_id', apex_application.g_flow_id));
        l_js_code := replace(l_js_code, '#p_flow_step_id#', apex_javascript.add_attribute('p_flow_step_id', apex_application.g_flow_step_id));
        l_js_code := replace(l_js_code, '#p_instance#', apex_javascript.add_attribute('p_instance', apex_util.get_session_State('APP_SESSION'),true,true));
        l_js_code := replace(l_js_code, '#x01#', replace(apex_javascript.add_attribute('x01', 'currFile.name'), '"', ''));
        l_js_code := replace(l_js_code, '#x02#', replace(apex_javascript.add_attribute('x02', 'currFile.type'), '"', ''));
    
        insert into debug_msg values (l_js_code);
    
        apex_javascript.add_inline_code(
            p_code => l_js_code
        );
        
    
        sys.htp.p('<div id="AjaxLoading" style="display:none;position:absolute;left:45%;top:45%;padding:10px;border:2px solid black;background:#FFF;" > Uploading..... <br /><img src="' || apex_application.g_image_prefix || 'processing3.gif" /></div>');
        sys.htp.p('<input type="file" id="' || p_item.name || '" value="' || p_value || '" multiple />');
        sys.htp.p('
    
            <button value="Submit" onclick="uploadFiles($x(' || p_item.name || ').files);" class="button-gray" type="button">
                <span>Submit</span>
            </button>
    
        ');
    
        return l_result;
    END render_file_item;


    function add_file (
        p_item   in apex_plugin.t_page_item,
        p_plugin in apex_plugin.t_plugin )
    return apex_plugin.t_page_item_ajax_result
    AS
        
    
        
        l_result apex_plugin.t_page_item_ajax_result;
        
        
        
        l_table_name p_item.attribute_01%type := p_item.attribute_01;
        l_filename p_item.attribute_02%type := p_item.attribute_02;
        l_mime_type p_item.attribute_03%type := p_item.attribute_03;
        l_blob_column p_item.attribute_04%type := p_item.attribute_04;
        l_blob BLOB := base64_to_blob(get_base64);
        l_foreign_key_item p_item.attribute_06%type := p_item.attribute_06;
        l_foreign_key_column p_item.attribute_07%type := p_item.attribute_07;
    
        
        c_foreign_key_col constant varchar2(200) := '#FOREIGN_KEY_COL#';
        c_foreign_key_col_replace constant varchar2(200) := ',' || l_foreign_key_column;
        
        c_foreign_key_val constant varchar2(200) := '#FOREIGN_KEY_VAL#';
        c_foreign_key_val_replace constant varchar2(200) := ',:4';
        
        l_insert_stmt varchar2(4000) := 'insert into ' ||  l_table_name || ' (' || l_filename || ',' || l_mime_type || ',' || l_blob_column || c_foreign_key_col || ') values (:1, :2, :3' || c_foreign_key_val || ')';
        l_insert_stmt2 varchar2(4000) := 'insert into ' ||  l_table_name || ' (' || l_filename || ',' || l_mime_type || ',' || l_blob_column || ') values (:1, :2, :3)';
    BEGIN
        
        IF l_foreign_key_item IS NOT NULL THEN --replace substitutions with actual values
            l_insert_stmt := REPLACE(l_insert_stmt, c_foreign_key_col, c_foreign_key_col_replace);
            l_insert_stmt := REPLACE(l_insert_stmt, c_foreign_key_val, c_foreign_key_val_replace);
            execute immediate l_insert_stmt using apex_application.g_x01, apex_application.g_x02, l_blob, v(l_foreign_key_item);
        ELSE --replace with empty strings
            l_insert_stmt := REPLACE(l_insert_stmt, c_foreign_key_col, '');
            l_insert_stmt := REPLACE(l_insert_stmt, c_foreign_key_val, '');
            execute immediate l_insert_stmt using apex_application.g_x01, apex_application.g_x02, l_blob;
        END IF;
        return l_result;
    END add_file;

END APEX_AJAX_UPLOAD;
