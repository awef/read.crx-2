app.view = {};

app.view.init = function() {
  $('#body')
    .addClass('pane-3');

  $('#tab_a, #tab_b').tab();

  $('#tab_resizer')
    .bind('mousedown', function(e) {
        var tab_a = document.getElementById('tab_a'),
            min_height = 50,
            max_height = document.body.offsetHeight - 50;

        e.preventDefault();
        $('<div>', {css: {
          position: 'absolute',
          left: 0,
          top: 0,
          width: '100%',
          height: '100%',
          'z-index': 999,
          cursor: 'row-resize'
        }})
          .bind('mousemove', function(e) {
              tab_a.style['height'] =
                  Math.max(Math.min(e.pageY, max_height), min_height) +
                  'px';
            })
          .bind('mouseup', function() {
              $(this).remove();
            })
          .appendTo('body');
      });

  $(document.documentElement)
    .delegate('.open_in_rcrx', 'click', function(e) {
        e.preventDefault();
        app.message.send('open', {
          url: this.href || this.getAttribute('data-href')
        });
      });
};

app.view.load_sidemenu = function(url) {
  app.bbsmenu.get(function(res) {
    var frag, category, board, h3, ul, li, a;

    if ('data' in res) {
      frag = document.createDocumentFragment();
      res.data.forEach(function(category) {
        h3 = document.createElement('h3');
        h3.innerText = category.title;
        frag.appendChild(h3);

        ul = document.createElement('ul');
        category.board.forEach(function(board) {
          li = document.createElement('li');
          a = document.createElement('a');
          a.className = 'open_in_rcrx';
          a.innerText = board.title;
          a.href = board.url;
          li.appendChild(a);
          ul.appendChild(li);
        });
        frag.appendChild(ul);
      });
    }

    $('#left_pane')
      .append(frag)
      .accordion();
  });
};

app.view.open_board = function(url) {
  app.board.get(url, function(res) {
    var $container, tbody, tr, td, fn, date, now, thread_how_old;
    fn = function(a) { return (a < 10 ? '0' : '') + a; };
    now = Date.now();

    if ('data' in res) {
      $container = $('#template > .view_board').clone();
      tbody = $container.find('tbody')[0];
      res.data.forEach(function(thread) {
        tr = document.createElement('tr');
        tr.className = 'open_in_rcrx';
        tr.setAttribute('data-href', thread.url);

        td = document.createElement('td');
        tr.appendChild(td);

        td = document.createElement('td');
        td.innerText = thread.title;
        tr.appendChild(td);

        td = document.createElement('td');
        td.innerText = thread.res_count;
        tr.appendChild(td);

        td = document.createElement('td');
        tr.appendChild(td);

        td = document.createElement('td');
        thread_how_old = (now - thread.created_at) / (24 * 60 * 60 * 1000);
        td.innerText = (thread.res_count / thread_how_old).toFixed(1);
        tr.appendChild(td);

        td = document.createElement('td');
        date = new Date(thread.created_at);
        td.innerText = date.getFullYear() +
            '/' + fn(date.getMonth() + 1) +
            '/' + fn(date.getDate()) +
            ' ' + fn(date.getHours()) +
            ':' + fn(date.getMinutes());
        tr.appendChild(td);

        tbody.appendChild(tr);
      });
      $container.appendTo('#tab_a');

      $('#tab_a').tab('add', {element: $container[0], title: url});
    }
    else {
      alert('error');
    }
  });
};

app.view.open_thread = function(url) {
  app.thread.get(url, function(res) {
    var $container;

    if ('data' in res) {
      $container = $('<div class="view_thread">');
      res.data.res.forEach(function(res) {
        var article, header, name, mail, other, message;

        article = document.createElement('article');

        header = document.createElement('header');
        article.appendChild(header);

        name = document.createElement('span');
        name.className = 'name';
        name.innerHTML = res.name
          .replace(/<(?!(?:\/?b|\/?font(?: color=[#a-zA-Z0-9]+)?)>)/g, '&lt;')
          .replace(/<\/b>(.*?)<b>/g, '<span class="ob">$1</span>');
        header.appendChild(name);

        mail = document.createElement('span');
        mail.className = 'mail';
        mail.innerText = res.mail;
        header.appendChild(mail);

        other = document.createElement('span');
        other.className = 'other';
        other.innerText = res.other;
        header.appendChild(other);

        message = document.createElement('div');
        message.className = 'message';
        message.innerHTML = res.message
          .replace(/<(?!(?:br|hr|\/?b)>).*?(?:>|$)/g, '')
          .replace(/(h)?(ttps?:\/\/[\w\-.!~*'();/?:@&=+$,%#]+)/g,
            '<a href="h$2" target="_blank" rel="noreferrer">$1$2</a>')
          .replace(/^\s*sssp:\/\/(img\.2ch\.net\/ico\/[\w\-_]+\.gif)\s*<br>/,
            '<img class="beicon" src="http://$1" /><br />');
        article.appendChild(message);

        $container[0].appendChild(article);
      });
      $('#tab_b').tab('add', {
        element: $container[0],
        title: res.data.title
      });
    }
    else {
      alert('error');
    }
  });
};
