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
        type: "",
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
        addMatcher(e) {
        e.preventDefault();
        axios.post(baseendpoint+'config',
            {
                service: 'biblio',
                table: 'matcher',
                params: {interface_id: this.interface_id, tag: this.tag, code: this.code, type: this.type}
            },
            {headers: { Authorization: apitoken }}
        ).then(response => {
            this.resetForm();
            this.fetchMatchers();
        });
        },
        resetForm() {
            this.interface_id = "";
            this.tag =  "";
            this.code = "";
            this.type = "";
            
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
                params: {tag: this.matcher.tag, code: this.matcher.code, type: this.matcher.type}
            },
            {headers: { Authorization: apitoken }}
        ).then(response => {
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
            this.$parent.fetchMatchers();
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
    props: ['matcher']
  });