// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery.min
//= require jquery_ujs
//= require bootstrap.min
//= require typeahead.bundle.min
//= require jquery.dataTables.min
//= require dataTables.bootstrap.min
//= require bootstrap-editable.min
//= require bulky
//= require_tree .

$(function() {
    // Setup X-Editable
    $.fn.editable.defaults.mode = 'inline';
    $.fn.editable.defaults.ajaxOptions = {
        type: 'put',
        dataType: 'json'
    };

    function editable_record_success(response, _value) {
        // Visual hint for the changed serial (on non bulky updates)
        if(response.saved && response.serial) {
            $('tr.soa .soa-serial').text(response.serial);
            $('tr.soa .soa-serial').fadeOut(100).fadeIn(500);
        }

        // Add bulk update to Bulky
        if (!response.saved) {
            bulky.update(response.record.id, response.attribute, response.value);
        }

        // Render the value returned by the server as
        // there are cases where the value is normalized (e.x. name)
        return { newValue: response.value };
    }

    $('table .editable').editable({
        success: editable_record_success,
        params: function (params) {
            // Don't actually save on bulky mode
            params.save = !bulky.enabled;
            return params;
        },
        validate: function (value) {
            rec_id = $(this).parents('tr').data('id');
            if (bulky.enabled && bulky.marked_for_delete(rec_id))
                return "This record is marked for deletion!";
        }
    });

    // Show priority on MX/SRV record only
    $('#record_type').change(function() {
        if ($(this).val() == 'MX') { // MX, default priority 10
            $('#record_prio.autohide').parents('div.form-group').removeClass('hidden');
            $('#record_prio.autodisable').prop('disabled', false);

            $('#record_prio').val('10');
        } else if ($(this).val() == 'SRV') { // SRV
            $('#record_prio').val('');
            $('#record_prio.autohide').parents('div.form-group').removeClass('hidden');
            $('#record_prio.autodisable').prop('disabled', false);
        } else {
            $('#record_prio').val('');
            $('#record_prio.autohide').parents('div.form-group').addClass('hidden');
            $('#record_prio.autodisable').prop('disabled', true);
        }
    });

    // Show master only on SLAVE domains
    $('#domain_type').change(function() {
        if ($(this).val() == 'SLAVE') {
            $('#domain_master').parents('div.form-group').removeClass('hidden');
        } else {
            $('#domain_master').parents('div.form-group').addClass('hidden');
        }
    });

    // Disable DNSSEC options
    $('#domain_dnssec').change(function() {
        if ($(this).val()== 'true') {
            $("#dnssec_fieldset").prop('disabled', false)
        } else {
            $("#dnssec_fieldset").prop('disabled', true);
        }
    });

    var searchMembersGroup = $('#js-search-member').data('group');
    var searchMembers = new Bloodhound({
        datumTokenizer: Bloodhound.tokenizers.obj.whitespace('email'),
        queryTokenizer: Bloodhound.tokenizers.whitespace,
        identify: function(obj) { return obj.id; },
        remote: {
            url: '/groups/' + searchMembersGroup + '/search_member.json?q=%QUERY',
            wildcard: '%QUERY'
        }
    });

    $('#js-search-member').typeahead({
        hint: true,
        minLength: 2
    }, {
        name: 'members',
        display: 'email',
        source: searchMembers
    });

    // Highlighter helper
    //
    // Applies 'highlight' class to the element followed by 'hl-' prefix
    function highlighter() {
        $('.highlight').removeClass('highlight');

        if (!window.location.hash)
            return;

        if (window.location.hash.indexOf('#hl-') == 0) {
            var id = window.location.hash.slice('hl-'.length + 1);

            $('#' + id).addClass('highlight');
        }
    }
    $(window).bind('hashchange', highlighter);

    highlighter();

    // Default tab helper
    function defaultTab() {
        if (!window.location.hash)
            return;

        if (window.location.hash.indexOf('#tab-') == 0) {
            var tab = window.location.hash.slice('tab-'.length + 1);

            $('#tab-link-' + tab).tab('show');
        }
    }

    defaultTab();

    $('table#domains').DataTable({
        paging: false,
        columnDefs: [{
            targets: 'no-order-and-search',
            orderable: false,
            searchable: false
        }],
    });
});
