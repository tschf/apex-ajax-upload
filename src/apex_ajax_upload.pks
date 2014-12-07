create or replace PACKAGE APEX_AJAX_UPLOAD AS 
  
    COLLECTION_NAME CONSTANT VARCHAR2(20) := 'AJAX_UPLOAD';
  
    function render_file_item(
        p_item                in apex_plugin.t_page_item,
        p_plugin              in apex_plugin.t_plugin,
        p_value               in varchar2,
        p_is_readonly         in boolean,
        p_is_printer_friendly in boolean )
    return apex_plugin.t_page_item_render_result;

    function add_file (
        p_item   in apex_plugin.t_page_item,
        p_plugin in apex_plugin.t_plugin )
    return apex_plugin.t_page_item_ajax_result;

END APEX_AJAX_UPLOAD;
