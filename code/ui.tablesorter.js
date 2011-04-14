(function($) {
  $.fn.tablesorter = function() {
    $(this).delegate('th', 'click', function() {
      var $table, $th, tbody,
          sort_index, sort_type, sort_order,
          data, data_keys;

      $th = $(this);
      $table = $th.closest('table');
      $table.hide();
      tbody = $table.find('tbody')[0];

      sort_index = $th.index();
      sort_type = $th.data('tablesorter_sort_type') || 'str';
      sort_order = $th.hasClass('tablesorter_sort_desc') ? 'asc' : 'desc';

      $th
        .siblings()
          .andSelf()
            .removeClass('tablesorter_sort_asc tablesorter_sort_desc');
      $th.addClass('tablesorter_sort_' + sort_order);

      data = {};
      Array.prototype.forEach.call(
          tbody.querySelectorAll('td:nth-child(' + (sort_index + 1) + ')'),
          function(td) {
            if (td.innerText in data) {
              data[td.innerText].push(td.parentNode);
            }
            else {
              data[td.innerText] = [td.parentNode];
            }
          }
      );

      data_keys = Object.keys(data);
      data_keys.sort(sort_type === 'num' ?
          function(a, b) { return a - b; } : undefined);

      if (sort_order === 'desc') {
        data_keys.reverse();
      }

      data_keys.forEach(function(val) {
        data[val].forEach(function(tr) {
          tbody.insertBefore(tr);
        });
      });

      $table.show();
    });
    return this;
  };
})(jQuery);
