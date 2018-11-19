new Vue({
    el: '#interfaceApp',
    created() {
        this.fetchData();	
    },
    data: {
        errors: [],
        configs: [],
        parameters: [],
        interface: "",
        name: "",
        type: "",
        endpoint_url: "",
        apikey: "",
        username: "",
        password: "",
        parametername: "",
        parametertype: "",
        parametervalue: ""
    },
    methods: {
        fetchData() {
        axios.get(baseendpoint+'config', {
          headers: { Authorization: apitoken },
          params: {
            service: 'biblio',
            table: 'interface'
          }
        }).then(response => {
            this.configs = response.data;
            });
        },
        fetchParameters(id) {
        axios.get(baseendpoint+'config', {
          headers: { Authorization: apitoken },
          params: {
            service: 'biblio',
            table: 'parameter',
            id: id,
          }
        }).then(response => {
            this.parameters = response.data;
            });
        },
        addParameter(params) {
        axios.post(baseendpoint+'config', 
          {
            service: 'biblio',
            table: 'parameter',
            params: params
          },
          {headers: { Authorization: apitoken }}
        ).then(response => {
              
            });
        },
        addConfig() {
        axios.post(baseendpoint+'config',
          {
            service: 'biblio',
            table: 'interface',
            params: {interface: this.interface, name: this.name, type: this.type, apikey: this.apikey, username: this.username, password: this.password, endpoint_url: this.endpoint_url}
          },
          {headers: { Authorization: apikey }}
        ).then(response => {
            this.fetchData();
            });
        },
        updateConfig(config) {
          axios.put(baseendpoint+'config',
          {
            service: 'biblio',
            table: 'interface',
            id: config.id,
            params: {interface: config.interface, name: config.name, type: config.type, apikey: config.apikey, username: config.username, password: config.password, endpoint_url: config.endpoint_url}
          },
          {headers: { Authorization: apitoken }}
        ).then(response => {
            
            });
        },
        deleteConfig(config) {
          axios.delete(baseendpoint+'config',
          {
            headers: { Authorization: apitoken },
            params: {
              service: 'biblio',
              table: 'interface',
              id: config.id
            }
          }
        ).then(response => {
            this.fetchData();
            });
        },
        deleteParameter(id) {
          axios.delete(baseendpoint+'config',
          {
            headers: { Authorization: apitoken },
            params: {
              service: 'biblio',
              table: 'parameter',
              id: id
            }
          }
        ).then(response => {
            });
        },
        checkForm(e) {
            var url_validate = /(ftp|http|https):\/\/(\w+:{0,1}\w*@)?(\S+)(:[0-9]+)?(\/|\/([\w#!:.?+=&%@!\-\/]))?/;
          if (this.name && this.interface && this.type && this.endpoint_url && url_validate.test(this.endpoint_url)) {
            this.addConfig();
          } 
          this.errors = [];

          if (!this.name) {
            this.errors.push('Name required.');
          }
          if (!this.interface) {
            this.errors.push('Interface required.');
          }
          if (!this.type) {
            this.errors.push('Type required.');
          }
          if (!this.endpoint_url) {
            this.errors.push('Url required.');
          }
          if (!url_validate.test(this.endpoint_url)) {
            this.errors.push('Incorrect url.');
          }
          e.preventDefault();
        }
    }
});
Vue.component('config-list', {
  template: "#list-items",
  data: function() {
    return {
      showUpdate: false
    }
  },
  methods: {
    updateConfig(config){
        this.showUpdate = false;
        this.$parent.updateConfig(config);
    },
    deleteConfig(config){
        this.showUpdate = false;
        this.$parent.deleteConfig(config);
    },
    fetchParameters(config){
        this.$parent.fetchParameters(config.id);
    },
    updateToggle(){
        this.showUpdate = !this.showUpdate;
    }
  },
  props: ['config', 'parameters']
});
Vue.component('modal-component', {
  template: "#parameter-modal",
  data: function() {
    return {
      parametername: "",
      parametertype: "",
      parametervalue: ""
    }
  },
  methods: {
    addParameter(interface_id, e) {
      e.preventDefault();
      var params = {interface_id: interface_id, name: this.parametername, type: this.parametertype, value: this.parametervalue};
      this.$parent.$parent.addParameter(params);
      this.$parent.$parent.fetchParameters(interface_id);
    },
    deleteParameter(parameter, e) {
      e.preventDefault();
      this.$parent.$parent.deleteParameter(parameter.id);
      this.$parent.$parent.fetchParameters(parameter.interface_id);
    }
  },
  props: ['config','parameters']
});