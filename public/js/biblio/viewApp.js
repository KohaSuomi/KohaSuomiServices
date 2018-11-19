new Vue({
    el: '#viewApp',
    created() {
        this.fetchExports();	
    },
    data: {
        results: [],
        status: "pending",
        isActive: false,
    },
    methods: {
        fetchExports() {
        axios.get(baseendpoint+'biblio', {
            headers: { Authorization: apitoken },
            params: {status: this.status}
        }).then(response => {
            this.results = response.data;
        }).catch(error => {
            console.log(error.response.data);
        });
        },
        changeStatus(status, event) {
            $(".nav-link").removeClass("active");
            $(event.target).addClass("active");
            this.results = [];
            this.status = status;
            this.fetchExports();
        },
    }
});
Vue.component('result-list', {
  template: "#list-items",
  props: ['result']
});