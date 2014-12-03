create or replace PACKAGE BODY APEX_AJAX_UPLOAD AS

    CHUNK_SIZE CONSTANT NUMBER := 32767;
    

    function get_region_id(p_region_name in varchar2) return varchar2
    AS
        l_region_id varchar2(200);
    BEGIN

        select coalesce(static_id, 'R'||region_id) into l_region_id
        from apex_application_page_regions
        where page_id = apex_application.g_flow_step_id and
        application_id = apex_application.g_flow_id and
        upper(region_name) = upper(p_region_name);
        
        return l_region_id;
        
        EXCEPTION
            WHEN
                NO_DATA_FOUND
                    THEN
                        RETURN NULL;
    
    END get_region_id;

    function base64_to_blob(p_base64 in clob) return BLOB
    AS
        l_blob BLOB;
    BEGIN
    
        l_blob := apex_web_service.clobbase642blob(p_base64);
        
        
        return l_blob;
    
    END;

    function get_binary_data(p_clob in out CLOB) return CLOB
    as
        l_clob CLOB;
    begin
    
        l_clob := substr(p_clob, instr(p_clob, ',')+1, length(p_clob));
        
        return l_clob;

    end get_binary_data;


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
        var currFile;
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
                currFile = this.fileList[gIndex++];
                
                
                var fileReader = new FileReader();
                fileReader.onload = addToCollection;
                fileReader.readAsDataURL(currFile);
            }
            
        }
        
        function addToCollection(e){
            
            var base64 = e.target.result;
            var totalLen = base64.length;
            var chunkSize = #CHUNK_SIZE#;
            var startIndex = 0;
            var currentChunk;
            var fArray = new Array();
            
            while (startIndex < totalLen){
            
                currentChunk = base64.substr(startIndex, chunkSize);
                
                fArray.push(currentChunk);
                
                startIndex += chunkSize;
            
            }
            
            $.post(
                'wwv_flow.show',  
                {
                    #p_request#
                    #p_flow_id#
                    #p_flow_step_id#
                    #p_instance#
                    #x01#
                    #x02#
                    #f01#
                },
                function s(d,s) {
                    $('##report_region_id#').trigger('apexrefresh');
                    uploadFiles();//do the next file
                }
            );
            
            
            
        }
        
        !';
        
        l_js_code := replace(l_js_code, '#CHUNK_SIZE#', CHUNK_SIZE);
        l_js_code := replace(l_js_code, '#item_name#', p_item.name);
        l_js_code := replace(l_js_code, '#report_region_id#', l_report_region_id);
        l_js_code := replace(l_js_code, '#p_request#', apex_javascript.add_attribute('p_request','PLUGIN=' || l_ajax_ident));
        l_js_code := replace(l_js_code, '#p_flow_id#', apex_javascript.add_attribute('p_flow_id', apex_application.g_flow_id));
        l_js_code := replace(l_js_code, '#p_flow_step_id#', apex_javascript.add_attribute('p_flow_step_id', apex_application.g_flow_step_id));
        l_js_code := replace(l_js_code, '#p_instance#', apex_javascript.add_attribute('p_instance', apex_util.get_session_State('APP_SESSION')));
        
        l_js_code := replace(l_js_code, '#x01#', replace(apex_javascript.add_attribute('x01', 'currFile.name'), '"', ''));
        l_js_code := replace(l_js_code, '#x02#', replace(apex_javascript.add_attribute('x02', 'currFile.type'), '"', ''));
        l_js_code := replace(l_js_code, '#f01#', replace(apex_javascript.add_attribute('f01', 'fArray', true, false), '"', ''));
    
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
        l_foreign_key_item p_item.attribute_06%type := p_item.attribute_06;
        l_foreign_key_column p_item.attribute_07%type := p_item.attribute_07;
    
        
        c_foreign_key_col constant varchar2(200) := '#FOREIGN_KEY_COL#';
        c_foreign_key_col_replace constant varchar2(200) := ',' || l_foreign_key_column;
        
        c_foreign_key_val constant varchar2(200) := '#FOREIGN_KEY_VAL#';
        c_foreign_key_val_replace constant varchar2(200) := ',:4';
        
        l_insert_stmt varchar2(4000) := 'insert into ' ||  l_table_name || ' (' || l_filename || ',' || l_mime_type || ',' || l_blob_column || c_foreign_key_col || ') values (:1, :2, :3' || c_foreign_key_val || ')';
        l_insert_stmt2 varchar2(4000) := 'insert into ' ||  l_table_name || ' (' || l_filename || ',' || l_mime_type || ',' || l_blob_column || ') values (:1, :2, :3)';
        
        l_data CLOB;
        l_blob BLOB;
        
        l_cnt NUMBER;
    BEGIN
    
        l_cnt := apex_application.g_f01.COUNT;
    
        dbms_lob.createtemporary(l_data, false, dbms_lob.session);
        
        for i in 1..apex_application.g_f01.COUNT
        LOOP
        
            dbms_lob.writeappend(
                lob_loc => l_data
              , amount => dbms_lob.getlength(apex_application.g_f01(i))
              , buffer => apex_application.g_f01(i)
            );
        
        END LOOP;
        
        l_blob := apex_web_service.clobbase642blob(get_binary_data(l_data));
        
        
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
