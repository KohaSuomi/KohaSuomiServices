new Vue({
    el: '#viewApp',
    created() {
        this.fetchExports();	
    },
    data: {
        results: [],
        status: "pending",
        isActive: false,
        page: 1,
        limit: 50,
        pages: 1,
        startCount: 1,
        endPage: 11,
        lastPage: 0
    },
    methods: {
        fetchExports() {
        axios.get(baseendpoint+'biblio', {
            headers: { Authorization: apitoken },
            params: {status: this.status, page: this.page, limit: this.limit}
        }).then(response => {
            this.results = response.data.results;
            this.pages = Math.ceil(response.data.count/this.limit);
            if (this.pages == 0) {
                this.pages = 1;
            }
            //this.pageShow();
            this.activate();
        }).catch(error => {
            console.log(error.response.data);
        });
        },
        changeStatus(status, event) {
            event.preventDefault();
            $(".nav-link").removeClass("active");
            $(event.target).addClass("active");
            this.results = [];
            this.status = status;
            this.page = 1;
            this.fetchExports();
        },
        changePage(e, page) {
            e.preventDefault();
            if (page < 1) {
                page = 1;
            }
            if (page > this.pages) {
                page = this.pages;
            }
            this.page = page;
            if (this.page == this.endPage) {
                this.startCount = this.page;
                this.endPage = this.endPage+10;
                this.lastPage = this.page;
            }
            if (this.page < this.lastPage) {
                this.startCount = this.page-10;
                this.endPage = this.lastPage;
                this.lastPage = this.lastPage-10;
            }
            this.fetchExports();
        },
        activate() {
            $(".page-link").removeClass("bg-primary text-white");
            $("[data-current="+this.page+"]").addClass("bg-primary text-white");
        },
        pageHide(page) {
            if (this.pages > 5) {
                if (this.endPage <= page && this.startCount < page) {
                    return true;
                }
                if (this.endPage >= page && this.startCount > page) {
                    return true;
                }
            }

            
        }
    }
});
Vue.component('result-list', {
  template: "#list-items",
  methods: {
    forceExport(e, id) {
        e.preventDefault();
        axios.put(baseendpoint+'biblio/'+id+'/force', {}, {headers: { Authorization: apitoken }}
        ).then(response => {
            this.$parent.fetchExports();
            this.$parent.changeStatus("pending", e);
        }).catch(error => {
            console.log(error.response.data);
        });
    },
    getRecord(e, id) {
        e.preventDefault();
        this.errors = [];
        axios.get(baseendpoint+'biblio/record/'+id, {headers: { Authorization: apitoken }}
        ).then(response => {
            $("#modalWrapper").find("#recordModal").remove();
            var html = $('<div id="recordModal" class="modal fade" role="dialog">\
                        <div class="modal-dialog modal-lg">\
                            <div class="modal-content">\
                                <div class="modal-header">\
                                    <h5 class="modal-title">Tietue</h5>\
                                    <button type="button" class="close" data-dismiss="modal" aria-label="Close">\
                                        <span aria-hidden="true">&times;</span>\
                                    </button>\
                                </div>\
                                <div id="recordWrapper" class="modal-body">\
                                </div>\
                                <div class="modal-footer">\
                                    <button type="button" class="btn btn-default" data-dismiss="modal">Sulje</button>\
                                </div>\
                            </div>\
                        </div>\
                    </div>');
            $('#modalWrapper').append(html);
            var source = parseRecord(response.data);
            $('#recordModal').find('#recordWrapper').append($('<div class="container">'+source+'</div>'));
            $('#recordModal').modal('toggle');
        }).catch(error => {
            this.errors.push(error.response.data.error);
        });
    }
  },
  filters: {
        moment: function (date) {
            return moment(date).locale("fi").format('D.M.Y H:mm:ss');
        }
    },
  props: ['result']
});

parseRecord = function (record) {
    var html = '<div>';
    html += '<li class="row"> <div class="col-xs-3 mr-2>';
    html += '<b>000</b></div><div class="col-xs-9">'+record.leader+'</li>';
    record.fields.forEach(function(v,i,a){
        if ($.isNumeric(v.tag)) {
            html += '<li class="row"><div class="col-xs-3 mr-2">';
        } else {
            html += '<li class="row hidden"><div class="col-xs-3  mr-2">';
        }
        html += '<b>'+v.tag;
        if (v.ind1) {html += ' '+v.ind1}
        if (v.ind2) {html += ' '+v.ind2}
        html += '</b></div><div class="col-xs-9">';
        if (v.subfields) {
            v.subfields.forEach(function(v,i,a){
                html += '<b>_'+v.code+'</b>'+v.value+'<br/>';
            });
        } else {
            html += v.value;
        }
        html += '</div></li>';
    });
    html += '</div>';
    return html;
}