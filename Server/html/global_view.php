<?php
// This script and data application were generated by AppGini 5.41
// Download AppGini for free from http://bigprof.com/appgini/download/

	$currDir=dirname(__FILE__);
	include("$currDir/defaultLang.php");
	include("$currDir/language.php");
	include("$currDir/lib.php");
	@include("$currDir/hooks/global.php");
	include("$currDir/global_dml.php");

	// mm: can the current member access this page?
	$perm=getTablePermissions('global');
	if(!$perm[0]){
		echo error_message($Translation['tableAccessDenied'], false);
		echo '<script>setTimeout("window.location=\'index.php?signOut=1\'", 2000);</script>';
		exit;
	}

	$x = new DataList;
	$x->TableName = "global";

	// Fields that can be displayed in the table view
	$x->QueryFieldsTV=array(   
		"`global`.`id`" => "id",
		"`global`.`defaultemail`" => "defaultemail",
		"`global`.`adminkeys`" => "adminkeys",
		"`global`.`clickhere`" => "clickhere",
		"concat('<img src=\"', if(`global`.`updateNames`, 'checked.gif', 'checkednot.gif'), '\" border=\"0\" />')" => "updateNames"
	);
	// mapping incoming sort by requests to actual query fields
	$x->SortFields = array(   
		1 => '`global`.`id`',
		2 => 2,
		3 => 3,
		4 => 4,
		5 => 5
	);

	// Fields that can be displayed in the csv file
	$x->QueryFieldsCSV=array(   
		"`global`.`id`" => "id",
		"`global`.`defaultemail`" => "defaultemail",
		"`global`.`adminkeys`" => "adminkeys",
		"`global`.`clickhere`" => "clickhere",
		"`global`.`updateNames`" => "updateNames"
	);
	// Fields that can be filtered
	$x->QueryFieldsFilters=array(   
		"`global`.`id`" => "ID",
		"`global`.`defaultemail`" => "Default Admin Email",
		"`global`.`adminkeys`" => "Admin Keys",
		"`global`.`clickhere`" => "Edit Settings",
		"`global`.`updateNames`" => "Update Host Names"
	);

	// Fields that can be quick searched
	$x->QueryFieldsQS=array(   
		"`global`.`id`" => "id",
		"`global`.`defaultemail`" => "defaultemail",
		"`global`.`adminkeys`" => "adminkeys",
		"`global`.`clickhere`" => "clickhere",
		"concat('<img src=\"', if(`global`.`updateNames`, 'checked.gif', 'checkednot.gif'), '\" border=\"0\" />')" => "updateNames"
	);

	// Lookup fields that can be used as filterers
	$x->filterers = array();

	$x->QueryFrom="`global` ";
	$x->QueryWhere='';
	$x->QueryOrder='';

	$x->AllowSelection = 1;
	$x->HideTableView = ($perm[2]==0 ? 1 : 0);
	$x->AllowDelete = $perm[4];
	$x->AllowMassDelete = false;
	$x->AllowInsert = $perm[1];
	$x->AllowUpdate = $perm[3];
	$x->SeparateDV = 0;
	$x->AllowDeleteOfParents = 0;
	$x->AllowFilters = 0;
	$x->AllowSavingFilters = 0;
	$x->AllowSorting = 0;
	$x->AllowNavigation = 1;
	$x->AllowPrinting = 1;
	$x->AllowCSV = 0;
	$x->RecordsPerPage = 1;
	$x->QuickSearch = 0;
	$x->QuickSearchText = $Translation["quick search"];
	$x->ScriptFileName = "global_view.php";
	$x->RedirectAfterInsert = "global_view.php?SelectedID=#ID#";
	$x->TableTitle = "Global Settings";
	$x->TableIcon = "table.gif";
	$x->PrimaryKey = "`global`.`id`";

	$x->ColWidth   = array(  150, 150);
	$x->ColCaption = array("Edit Settings", "Update Host Names");
	$x->ColFieldName = array('clickhere', 'updateNames');
	$x->ColNumber  = array(4, 5);

	$x->Template = 'templates/global_templateTV.html';
	$x->SelectedTemplate = 'templates/global_templateTVS.html';
	$x->ShowTableHeader = 1;
	$x->ShowRecordSlots = 0;
	$x->HighlightColor = '#FFF0C2';

	// mm: build the query based on current member's permissions
	$DisplayRecords = $_REQUEST['DisplayRecords'];
	if(!in_array($DisplayRecords, array('user', 'group'))){ $DisplayRecords = 'all'; }
	if($perm[2]==1 || ($perm[2]>1 && $DisplayRecords=='user' && !$_REQUEST['NoFilter_x'])){ // view owner only
		$x->QueryFrom.=', membership_userrecords';
		$x->QueryWhere="where `global`.`id`=membership_userrecords.pkValue and membership_userrecords.tableName='global' and lcase(membership_userrecords.memberID)='".getLoggedMemberID()."'";
	}elseif($perm[2]==2 || ($perm[2]>2 && $DisplayRecords=='group' && !$_REQUEST['NoFilter_x'])){ // view group only
		$x->QueryFrom.=', membership_userrecords';
		$x->QueryWhere="where `global`.`id`=membership_userrecords.pkValue and membership_userrecords.tableName='global' and membership_userrecords.groupID='".getLoggedGroupID()."'";
	}elseif($perm[2]==3){ // view all
		// no further action
	}elseif($perm[2]==0){ // view none
		$x->QueryFields = array("Not enough permissions" => "NEP");
		$x->QueryFrom = '`global`';
		$x->QueryWhere = '';
		$x->DefaultSortField = '';
	}
	// hook: global_init
	$render=TRUE;
	if(function_exists('global_init')){
		$args=array();
		$render=global_init($x, getMemberInfo(), $args);
	}

	if($render) $x->Render();

	// hook: global_header
	$headerCode='';
	if(function_exists('global_header')){
		$args=array();
		$headerCode=global_header($x->ContentType, getMemberInfo(), $args);
	}  
	if(!$headerCode){
		include_once("$currDir/header.php"); 
	}else{
		ob_start(); include_once("$currDir/header.php"); $dHeader=ob_get_contents(); ob_end_clean();
		echo str_replace('<%%HEADER%%>', $dHeader, $headerCode);
	}

	echo $x->HTML;
	// hook: global_footer
	$footerCode='';
	if(function_exists('global_footer')){
		$args=array();
		$footerCode=global_footer($x->ContentType, getMemberInfo(), $args);
	}  
	if(!$footerCode){
		include_once("$currDir/footer.php"); 
	}else{
		ob_start(); include_once("$currDir/footer.php"); $dFooter=ob_get_contents(); ob_end_clean();
		echo str_replace('<%%FOOTER%%>', $dFooter, $footerCode);
	}
?>