const value=process.env.DATABASE_URL;
if(!value)throw new Error('Tests require DATABASE_URL for a disposable local database ending in _test');
const url=new URL(value);
if(!['postgres:','postgresql:'].includes(url.protocol)||!['localhost','127.0.0.1','[::1]'].includes(url.hostname)||!decodeURIComponent(url.pathname.slice(1)).endsWith('_test')){
 throw new Error('Refusing tests: use a disposable loopback PostgreSQL database ending in _test');
}
console.log('Disposable test database guard passed.');
