create or replace PACKAGE BODY APEX_AJAX_UPLOAD AS

    CHUNK_SIZE CONSTANT NUMBER := 20000;
    POST_SIZE CONSTANT NUMBER := 300000;
    
    MAX_PROGRESS_BARS CONSTANT NUMBER := 5;
    
    UPLOADING_CMD CONSTANT NUMBER := 1;
    SAVE_CMD CONSTANT NUMBER := 2;
    CANCEL_CMD CONSTANT NUMBER := 3;
    
    

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
        l_report_region_id p_item.attribute_08%type;
        
        l_js_code varchar2(8000);
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
        
        var _completeTransfers,
            _totalProgressBar,
            _isUploading = false;
            
        function isShowProgressBar(fileIndex, fileListSize){
        
        
            var isAdded = (uploaderJQuery('#file' + fileIndex + 'progressBar').size() > 0 );
            var notExceedMax = (fileListSize <= #MAX_PROGRESS_BARS#);
            return !(isAdded) && notExceedMax;
        
        }
            
        function updateNthProgressBar(n, val){
        
            uploaderJQuery('#file' + n + 'progressBar').progressbar("option", "value", val)
        
        }
            
        function addNewProgressBar( fileIndex, fileName){
        
            
        
            var htmlCode = getNewProgressCode(fileIndex, fileName);
            apex.jQuery('#individualProgress').append(htmlCode);
            
            uploaderJQuery('#file' + fileIndex + 'progressBar').progressbar({value: false});
        
        }
            
        function getNewProgressCode(fileIndex, fileName){
        
            var html;
            html = '<div id="file' + fileIndex + 'progressBar" class="progressBar">';
            html += '<div class="progressLabel">' + fileName + '</div>';
            html += '</div>'
        
        
            return html;
        }
        
        
        function showProgressBar(n){
        
            apex.jQuery('#totalNumFiles').text(n)
        
            if(!(_totalProgressBar))
                _totalProgressBar = uploaderJQuery('#totalProgressBar');
        
            apex.jQuery('#progressDialog').dialog({
            
                dialogClass: "progressDialog",
                buttons: [
                    {
                        "text" : "Cancel Upload(s)",
                        "click" : function() { _isUploading = false; apex.jQuery(this).dialog("close");}       
                    }
                ],
                position: {
                    my: 'center',
                    at: 'top'
                    
                }
            });
            
            _totalProgressBar.progressbar({
                value: false
              , complete: function() {
                apex.jQuery('#progressDialog').dialog("option", "buttons", [{ text: "Close", click: function() { hideProgressBar(); } }])
              }
            });
            
        }
        
        function hideProgressBar(){
        
            apex.jQuery('#progressDialog').dialog("close");
            apex.jQuery('#individualProgress').empty();
        
        }
        
        function uploadFiles(fileList){
           
            showProgressBar(fileList.length);
            _completeTransfers = 0;
            _isUploading = true;
            
            if (fileList.length >= 2)
                apex.jQuery('#totalProgressBar').show();
            else
                apex.jQuery('#totalProgressBar').hide();
             
           
            for (var j = 0, fileIndex = 0; j < fileList.length; j++){
                var thisFile = fileList[j];
            
                var reader = new FileReader();
                
                //Example adapted from: http://www.html5rocks.com/en/tutorials/file/dndfiles/#toc-reading-files
                reader.onload = (function(theFile){
                    return function(e) {
                        doUpload(fileIndex++, 0, e.target.result, theFile.name, theFile.type, fileList.length);
                    
                    };
                })(thisFile);
                
                reader.readAsDataURL(thisFile)
                
            
            }
        }
        
        
        function doUpload(fileIndex, piece, base64, fileName, mimeType, totalFiles){
        
            if (isShowProgressBar(fileIndex, totalFiles)) {
                addNewProgressBar(fileIndex, fileName);
            }
        
            var itemName = '#item_name#';
            var totalLen = base64.length;
            
            var chunkSize = #CHUNK_SIZE#;
            var postSize = #POST_SIZE#;
            
            var UPLOADING_CMD = #UPLOADING_CMD#;
            var SAVE_CMD = #SAVE_CMD#;
            var CANCEL_CMD = #CANCEL_CMD#;
            var refreshRegion = '#report_region_id#';
            
            var filePieces = Math.floor(totalLen/postSize)+1;
            
            var currentPiece = base64.substr(piece*postSize, postSize);
        
            if (_isUploading == false)
                currentCmd = CANCEL_CMD;
            else 
                currentCmd = (piece+1 == filePieces) ? SAVE_CMD : UPLOADING_CMD;
            
            
            var chunkIndex = 0;
            var fArray = new Array();
            var pieceLen = currentPiece.length;
            
            while (chunkIndex < pieceLen){
                var fbit = currentPiece.substr(chunkIndex, chunkSize);
                fArray.push(fbit);
                chunkIndex += chunkSize;   
            }
            
            if (_isUploading){
                apex.jQuery.ajax({
                    type: 'POST',
                    url: 'wwv_flow.show',
                    data: {
                        #p_request#
                        #p_flow_id#
                        #p_flow_step_id#
                        #p_instance#
                        #x01#
                        #x02#
                        #x03#
                        #x04#
                        #x05#
                        #f01#
                    },
                    success: function() {
                    
                        updateNthProgressBar(fileIndex, (++piece/filePieces)*100);
                                                
                        if ( piece < filePieces  ){
                            doUpload(fileIndex, piece, base64, fileName, mimeType, totalFiles); 
                        
                        } else {
                        
                            ++_completeTransfers;
                            
                            if (refreshRegion){
                                apex.jQuery('#' + refreshRegion).trigger('apexrefresh');
                            }
                            
                            _totalProgressBar.progressbar("value", (_completeTransfers / totalFiles) * 100);
                        
                            if (_completeTransfers == totalFiles){
                                if (itemName) {
                                    apex.jQuery('#' + itemName).val('');
                                }
                            }
                        
                        }
                    },
                    async:true
                });
            } else {
                apex.jQuery({
                    type: 'POST',
                    url: 'wwv_flow.show',
                    data: {
                        #p_request#
                        #p_flow_id#
                        #p_flow_step_id#
                        #p_instance#
                        #x04#
                    },
                    async: true
                });    
            }
            
        }
        
        !';
        
        l_js_code := replace(l_js_code, '#CHUNK_SIZE#', CHUNK_SIZE);
        l_js_code := replace(l_js_code, '#POST_SIZE#', POST_SIZE);
        l_js_code := replace(l_js_code, '#UPLOADING_CMD#', UPLOADING_CMD);
        l_js_code := replace(l_js_code, '#MAX_PROGRESS_BARS#', MAX_PROGRESS_BARS);
        l_js_code := replace(l_js_code, '#SAVE_CMD#', SAVE_CMD);
        l_js_code := replace(l_js_code, '#CANCEL_CMD#', CANCEL_CMD);
        l_js_code := replace(l_js_code, '#item_name#', p_item.name);
        l_js_code := replace(l_js_code, '#report_region_id#', l_report_region_id);
        l_js_code := replace(l_js_code, '#p_request#', apex_javascript.add_attribute('p_request','PLUGIN=' || l_ajax_ident));
        l_js_code := replace(l_js_code, '#p_flow_id#', apex_javascript.add_attribute('p_flow_id', apex_application.g_flow_id));
        l_js_code := replace(l_js_code, '#p_flow_step_id#', apex_javascript.add_attribute('p_flow_step_id', apex_application.g_flow_step_id));
        l_js_code := replace(l_js_code, '#p_instance#', apex_javascript.add_attribute('p_instance', apex_util.get_session_State('APP_SESSION')));
        
        l_js_code := replace(l_js_code, '#x01#', replace(apex_javascript.add_attribute('x01', 'fileName'), '"', ''));
        l_js_code := replace(l_js_code, '#x02#', replace(apex_javascript.add_attribute('x02', 'mimeType'), '"', ''));
        l_js_code := replace(l_js_code, '#x03#', replace(apex_javascript.add_attribute('x03', 'piece'), '"', ''));
        l_js_code := replace(l_js_code, '#x04#', replace(apex_javascript.add_attribute('x04', 'currentCmd'), '"', ''));
        l_js_code := replace(l_js_code, '#x05#', replace(apex_javascript.add_attribute('x05', 'fileIndex'), '"', ''));
        l_js_code := replace(l_js_code, '#f01#', replace(apex_javascript.add_attribute('f01', 'fArray', true, false), '"', ''));
    
        apex_javascript.add_inline_code(
            p_code => l_js_code
        );
                
        apex_css.add(
        
            p_css => q'!
            
                #progressDialog {
                    display: none;
                }
                
                .progressDialog .ui-dialog-titlebar {
                    display: none;
                }
                
                .progressDialog {
                
                    margin-top: 100px;
                
                }
                
                .progressBar {
                    margin-top: 20px;
                    text-align: center;
                    overflow: hidden;
                    position: relative;
                    vertical-align: middle;
                    line-height: 35px;
                }
                
                /*.ui-progressbar {
                    position: relative;
                }*/
                
                .progressLabel {
                    float: left;
                    width: 100%;
                    height: 100%;
                    position: absolute;
                    vertical-align: middle;
                }
            
            !'
        
        );
       
        apex_javascript.add_library(
            p_name => 'jquery-1.11.1.min'
          , p_directory => p_plugin.file_prefix  );
          
        apex_javascript.add_inline_code(
            p_code => 'var uploaderJQuery = jQuery;'
        );          
        apex_javascript.add_library(
            p_name => 'jquery-ui.min'
          , p_directory => p_plugin.file_prefix  );  
        apex_css.add_file(
            p_name => 'jquery-ui.min'
          , p_directory => p_plugin.file_prefix  
        );
        
        sys.htp.p('
        <div id="progressDialog">
            <div id="progressLabel">Uploading <span id="totalNumFiles">0</span> file(s)</div>
            <div id="individualProgress">
            
            </div>
            <div id="totalProgressBar" class="progressBar"><div class="progressLabel">Overall Progress</div></div>
        </div>');        
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
        
        --item attributes
        l_table_name p_item.attribute_01%type := p_item.attribute_01;
        l_filename_col p_item.attribute_02%type := p_item.attribute_02;
        l_mime_type_col p_item.attribute_03%type := p_item.attribute_03;
        l_blob_col p_item.attribute_04%type := p_item.attribute_04;
        l_foreign_key_item p_item.attribute_06%type := p_item.attribute_06;
        l_foreign_key_column p_item.attribute_07%type := p_item.attribute_07;
        
        --constants
        c_foreign_key_col constant varchar2(20) := '#FOREIGN_KEY_COL#';
        c_foreign_key_col_replace constant varchar2(20) := ',' || l_foreign_key_column;
        
        c_foreign_key_val constant varchar2(20) := '#FOREIGN_KEY_VAL#';
        c_foreign_key_val_replace constant varchar2(5) := ',:4';       
        
        C_FIRST_PIECE CONSTANT NUMBER := 0;
        C_FILE_PIECES_LIMIT CONSTANT NUMBER := 30;
         
    
        --dynamic SQL
        l_insert_stmt varchar2(4000) := 'insert into ' ||  l_table_name || ' (' || l_filename_col || ',' || l_mime_type_col || ',' || l_blob_col || c_foreign_key_col || ') values (:1, :2, :3' || c_foreign_key_val || ')';
        l_insert_stmt2 varchar2(4000) := 'insert into ' ||  l_table_name || ' (' || l_filename_col || ',' || l_mime_type_col || ',' || l_blob_col || ') values (:1, :2, :3)';
        
        --AJAX input
        l_filename varchar2(255);
        l_mime_type varchar2(255);
        l_post_index NUMBER;
        l_file_index NUMBER;
        l_current_cmd NUMBER;
        l_collection_name apex_collections.collection_name%type;
        
        --custom types
        CURSOR file_collection is
        select 
          seq_id
        , c001 filename
        , c002 mime_type
        , n001 post_index
        , dbms_lob.getlength(clob001) clob_len
        , clob001 base64_Data
        from apex_collections
        where collection_name = l_collection_name
        order by n001;
        
        type t_file_pieces is table of file_collection%rowtype
        index by PLS_INTEGER;
        
        --output
        l_file_pieces t_file_pieces;
        l_data_chunk CLOB;
        l_whole_data CLOB;
        l_blob BLOB;
        
        l_error varchar2(4000);
        
    BEGIN
        l_filename := apex_application.g_x01;
        l_mime_type := apex_application.g_x02;
        l_post_index := apex_application.g_x03;
        l_current_cmd := apex_application.g_x04;
        l_file_index := apex_application.g_x05;
        
        l_collection_name := COLLECTION_NAME||l_file_index;
        
        if l_current_cmd = CANCEL_CMD
        then
            apex_collection.delete_collection(l_collection_name);
            
            return l_result;
        end if;
    
        dbms_lob.createtemporary(l_data_chunk, false);
        
        for i in 1..apex_application.g_f01.COUNT
        LOOP
        
            dbms_lob.writeappend(
                lob_loc => l_data_chunk
              , amount => dbms_lob.getlength(apex_application.g_f01(i))
              , buffer => apex_application.g_f01(i)
            );
        
        END LOOP;
        
        
        
        if l_post_index = C_FIRST_PIECE
        then
        
            apex_collection.create_or_truncate_collection(l_collection_name);
        
        end if;
        
        dbms_lob.createtemporary(l_whole_data, false);
        
        if l_current_cmd = UPLOADING_CMD
        then
            apex_collection.add_member(
                p_collection_name => l_collection_name
              , p_c001 => l_filename
              , p_c002 => l_mime_type
              , p_n001 => l_post_index
              , p_clob001 => l_data_chunk
            );
            
            
        elsif l_current_cmd = SAVE_CMD
        then
            open file_collection;
            loop
                fetch file_collection
                    bulk collect into l_file_pieces limit C_FILE_PIECES_LIMIT;
            
                for i in 1..l_file_pieces.COUNT
                LOOP
                    dbms_lob.append(
                        dest_lob => l_whole_data
                      , src_lob => l_file_pieces(i).base64_Data
                    );
                END LOOP;
            
                exit when l_file_pieces.COUNT < C_FILE_PIECES_LIMIT;
                
            end loop;
            
            close file_collection;
            
            
            
            dbms_lob.append(
                dest_lob => l_whole_data
              , src_lob => l_data_chunk
            );
            
            l_blob := apex_web_service.clobbase642blob(get_binary_data(l_whole_data));
            
            IF l_foreign_key_item IS NOT NULL THEN 
                l_insert_stmt := REPLACE(l_insert_stmt, c_foreign_key_col, c_foreign_key_col_replace);
                l_insert_stmt := REPLACE(l_insert_stmt, c_foreign_key_val, c_foreign_key_val_replace);
                execute immediate l_insert_stmt using apex_application.g_x01, apex_application.g_x02, l_blob, v(l_foreign_key_item);
            ELSE 
                l_insert_stmt := REPLACE(l_insert_stmt, c_foreign_key_col, '');
                l_insert_stmt := REPLACE(l_insert_stmt, c_foreign_key_val, '');
                execute immediate l_insert_stmt using apex_application.g_x01, apex_application.g_x02, l_blob;
            END IF;
            
            apex_collection.delete_collection(l_collection_name);
         
        end if;
        
        
        return l_result;
    END add_file;

END APEX_AJAX_UPLOAD;
