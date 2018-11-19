new Vue({
    el: '#loginApp',
    data: {
        errors: [],
        username: "",
        password: "",
    },
    methods: {
        login() {
        var form = new FormData();
        form.set("userid", this.username);
        form.set("password", this.password);
        axios.post(loginpath, form
        ).then(response => {
            this.setSession(response.data);
          }).catch(error => {
            this.errors = [];
            this.errors.push(error.response.data.error);
          });
        },
        setSession(data) {
        axios.post(baseendpoint+'auth', data, {headers: { Authorization: apikey }, withCredentials: true}
        ).then(response => {
            window.location.href = servicepath;
          }).catch(error => {
            this.errors = [];
            this.errors.push(error.response.data.error);
          });
        }
    }
});