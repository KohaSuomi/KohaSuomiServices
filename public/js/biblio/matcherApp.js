new Vue({
    el: '#matcherApp',
    created() {
        this.fetchMatchers();	
        this.fetchInterfaces();	
    },
    data: {
        errors: [],
        interfaces: [],
        matchers: [],
        interface_id: "",
        tag: "",
        code: "",
        value: "",
        type: "",
        filter_id: ""
    },
    methods: {
        fetchInterfaces() {
        axios.get(baseendpoint+'config', {
          headers: { Authorization: apitoken },
          params: {
            service: 'biblio',
            table: 'interface'
          }
        }).then(response => {
            this.interfaces = response.data;
            });
        },
        fetchMatchers() {
        axios.get(baseendpoint+'config', {
            headers: { Authorization: apitoken },
            params: {
            service: 'biblio',
            table: 'matcher'
            }
        }).then(response => {
            this.matchers = response.data;
            });
        },
        getMatchers() {
            this.matchers = [];
            this.interface_id = "";
            axios.get(baseendpoint+'config', {
                headers: { Authorization: apitoken },
                params: {
                service: 'biblio',
                table: 'matcher',
                interface_id: this.filter_id
                }
            }).then(response => {
                this.matchers = response.data;
                this.interface_id = this.filter_id;
                });
        },
        addMatcher(e) {
        e.preventDefault();
        axios.post(baseendpoint+'config',
            {
                service: 'biblio',
                table: 'matcher',
                params: {interface_id: this.interface_id, tag: this.tag, code: this.code, value: this.value, type: this.type}
            },
            {headers: { Authorization: apitoken }}
        ).then(response => {
            this.resetForm();
            if (this.filter_id) {
                this.getMatchers();
            } else {
                this.fetchMatchers();
            }
        });
        },
        resetForm() {
            this.interface_id = "";
            this.tag =  "";
            this.code = "";
            this.value = "";
            this.type = "";
        },
        selectFilter(name, e) {
            e.preventDefault();
            $(".nav-link").removeClass("active");
            $(e.target).addClass("active");

            if (name == "select") {
                $("#select-interfaces").removeClass("d-none");
            } else {
                this.filter_id = "";
                this.interface_id = "";
                $("#select-interfaces").addClass("d-none");
                this.fetchMatchers();
            }
        }
}
});
Vue.component('matcher-list', {
    template: "#list-matchers",
    created() {
        this.getInterface();
    },
    data: function() {
      return {
        showUpdate: false,
        interface_name: "",
      }
    },
    methods: {
        updateMatcher(){
        axios.put(baseendpoint+'config',
            {
                service: 'biblio',
                table: 'matcher',
                id: this.matcher.id,
                params: {tag: this.matcher.tag, code: this.matcher.code, value: this.matcher.value, type: this.matcher.type}
            },
            {headers: { Authorization: apitoken }}
        ).then(response => {
            console.log(this.matcher);
            this.showUpdate = false;
        }).catch(error => {
            console.log(error.response.data);
        });
        },
        deleteMatcher() {
        axios.delete(baseendpoint+'config',
        {
            headers: { Authorization: apitoken },
            params: {
                service: 'biblio',
                table: 'matcher',
                id: this.matcher.id
            }
        }
        ).then(response => {
            if (this.filter_id) {
                this.$parent.getMatchers();
            } else {
                this.$parent.fetchMatchers();
            }
        }).catch(error => {
            console.log(error.response.data);
        });
        },
        getInterface() {
        axios.get(baseendpoint+'config', {
            headers: { Authorization: apitoken },
            params: {
                service: 'biblio',
                table: 'interface',
                id: this.matcher.interface_id,
            }
        }).then(response => {
            this.interface_name = response.data[0].name+" / "+response.data[0].type;
        }).catch(error => {
                console.log(error.response.data);
        });
        },
        updateToggle(){
            this.showUpdate = !this.showUpdate;
        }
    },
    props: ['matcher', 'filter_id']
  });