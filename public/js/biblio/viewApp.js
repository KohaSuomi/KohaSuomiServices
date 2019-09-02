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
        pages: 1
    },
    methods: {
        fetchExports() {
        axios.get(baseendpoint+'biblio', {
            headers: { Authorization: apitoken },
            params: {status: this.status, page: this.page, limit: this.limit}
        }).then(response => {
            this.results = response.data.results;
            this.pages = Math.ceil(response.data.count/this.limit);
        }).catch(error => {
            console.log(error.response.data);
        });
        },
        changeStatus(status, event) {
            $(".nav-link").removeClass("active");
            $(event.target).addClass("active");
            this.results = [];
            this.status = status;
            this.page = 1;
            this.fetchExports();
        },
        changePage(e, page) {
            e.preventDefault();
            this.page = page;
            this.fetchExports();
        }
    }
});
Vue.component('result-list', {
  template: "#list-items",
  props: ['result']
});