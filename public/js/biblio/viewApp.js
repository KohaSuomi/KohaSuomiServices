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
  props: ['result']
});