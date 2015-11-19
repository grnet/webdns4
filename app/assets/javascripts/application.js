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
//= require_tree .

$(function() {

    // Show priority on MX/SRV record only
    $('#record_type').change(function() {
        if ($(this).val() == 'MX' || $(this).val() == 'SRV') {
            $('#record_prio').parents('div.form-group').removeClass('hidden');
        } else {
            $('#record_prio').parents('div.form-group').addClass('hidden');
        }
    });

    var searchMembersGroup = $('#js-search-member').data('group');
    var searchMembers = new Bloodhound({
        datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
        queryTokenizer: Bloodhound.tokenizers.whitespace,
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
});
